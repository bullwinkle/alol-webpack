#Iconto.REST.LeclickRestaurant
#Iconto.REST.LeclickRestaurantCollection
#Iconto.REST.LeclickReserve
#Iconto.REST.LeclickReserveCollection
#Iconto.REST.LeclickCity
#Iconto.REST.LeclickCityCollection


Iconto.module 'order.views', (Order) ->

	GEOCODE_BASE_URL = 'https://maps.googleapis.com/maps/api/geocode/json'

	inherit = Iconto.shared.helpers.inherit

	class Order.RestaurantItem extends Marionette.ItemView
		template: JST['order/templates/restaurant/restaurant-item']
		tagName: 'li'
		className: 'button list-item menu-item restaurant-item'

		behaviors:
			Epoxy: {}

		ui: {}

		events:
			'click': 'onElClick'

		modelEvents: {}

		onElClick: =>
			model = _.result @, 'model.toJSON'
			@trigger 'click', model

	class Order.RestaurantBooking extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
		template: JST['order/templates/restaurant/restaurant-booking']
		className: 'order-view restaurants-booking mobile-layout'
		childView: Order.RestaurantItem
		childViewContainer: '.restaurants-list'

		behaviors:
			Layout: {}
			Epoxy: {}
#			InfiniteScroll:
#				scrollable: '.view-content'
			Form:
				validated: ['model','state']
				submit: 'button.submit-button'
				events:
					submit: 'form'

		ui:
			form: 'form'
			submitButton: 'button.submit-button'
			citySelect: '#city-select'

			slidableRegionMap: '.slidable-region-right.map-region'
			slidableRegionMapContainer: '.slidable-region-right.map-region .google-map-container'
			showeSlidableRegionMap: '.show-slidable-region-map'
			closeSlidableRegionMap: '.slidable-region-right.map-region .close-slidable-region'

			slidableRegionOrderForm: '.slidable-region-right.order-form'
			showeSlidableRegionOrderForm: '.show-slidable-region-order-form'
			closeSlidableRegionOrderForm: '.slidable-region-right.order-form .close-slidable-region'

			showRestaurantThumbnail: '.restaurant-thumbnail'

		events:
			'input': 'onInput'

			'click @ui.showeSlidableRegionMap': 'onShoweSlidableRegionMapClick'
			'click @ui.closeSlidableRegionMap': 'onCloseSlidableRegionMapClick'

			'click @ui.showeSlidableRegionOrderForm': 'onShoweSlidableRegionOrderFormClick'
			'click @ui.closeSlidableRegionOrderForm': 'onCloseSlidableRegionOrderFormClick'

			'click @ui.showRestaurantThumbnail': 'onRestaurantThumbnailClick'

		model: new Iconto.REST.LeclickReserve()

		collection: new Iconto.REST.LeclickRestaurantCollection()

		modelEvents: {}

		collectionEvents:
			'add remove reset change': 'onCollectionChange'

		bindingSources: =>
			state: @state
			infiniteScrollState: @infiniteScrollState

		initialize: ->
			state = if @options.state and @options.state instanceof Backbone.Model then @options.state.toJSON() else {}
			state.isLoading  = false
			@state = new Iconto.shared.models.BaseStateViewModel state
			delete @options.state

			@state.set
				empty: false
				isAddressSelectVisible: false
				isOrderFormVisible: false
				isCommentAreaVisible: false
				isAddressLoading: false
				definedAddress:''
				lat: 0
				lon: 0
				cities: []
				selectedCity: null
				companyQuery: ''
				restaurants: []
				selectedRestaurant: null
				when_time: 0
				when_date: 0
				isLoadingMore: true

			@listenTo @state,
				'change:companyQuery': _.debounce @reload, 300
				'change:lat': @reload

				'change:when_time': @setTime
				'change:when_date': @setTime

			user = @state.get('user') || {}
			firstName = _.get user, 'first_name',''
			lastName = _.get user, 'last_name',''
			fullName = "#{firstName} #{lastName}".trim()

			@model.set 'phone', _.get(user, 'phone', '')
			@model.set 'user_name', fullName

		onRender: =>
			now = moment()
			nowDate = now.format('YYYY-MM-DD')
			nowTime = now.add(15,'minutes').format('HH:mm')

			@state.set
				when_time : nowTime
				when_date : nowDate

			@model.set
				phone: @options.phone if @options.phone

			@mapView = new Iconto.shared.views.map.AddressFinderMapView().render()

			@ui.slidableRegionMapContainer.html @mapView.el
			@listenTo @mapView,
				'map:idle': => @state.set 'isAddressLoading', true
				'map:addressDefined': (location) =>
					@state.set
						isAddressLoading: false
						lat: _.get location, 'coords.lat'
						lon: _.get location, 'coords.lon'
						definedAddress: _.get location, 'address'

			Iconto.shared.services.geo.getCurrentPosition()
			.then (position) =>
				lat = _.get position, 'coords.latitude'
				lon = _.get position, 'coords.longitude'
				{lat, lon}
			.catch (err) =>
				lat = 55.75694
				lon = 37.62346
				{lat, lon}
			.then ({lat, lon}) =>
				@state.set {lat, lon}, silent: true
				@mapView.setCenter {lat, lon}

				citiesPromise = (new Iconto.REST.CityCollection()).fetch
					country_id: 6
					limit: 20

				currentCityPromise = (new Iconto.REST.City()).fetch
					lat: lat
					lon: lon

				Q.settle [citiesPromise,currentCityPromise]
			.then ([cities, currentCity]) =>
				citiesValue = _.result cities, 'value'
				citiesIsResolved = _.result cities, 'isResolved'

				currentCityValue = _.get _.result(currentCity, 'value'), 'items[0]'
				currentCityIsResolved = _.result currentCity, 'isResolved'

				all = citiesIsResolved and currentCityIsResolved
				any = citiesIsResolved or currentCityIsResolved
				noOne = !citiesIsResolved and !currentCityIsResolved
				if all
					currentCityIndex = 0
					@state.set 'cities', _.map citiesValue, (city, index, cities) =>
						if city.id is currentCityValue.id then currentCityIndex = index
						city.label = city.name
						city.value = city.id
						city
					@ui.citySelect.find('option').eq(currentCityIndex).attr 'selected', 'selected'

				else if citiesIsResolved
					cities = citiesValue.map (city, index, cities) =>
						city.label = city.name
						city.value = city.id
						city
					cities.unshift
						label: 'Выберите город'
						value: ''
					@state.set 'cities', cities
					@ui.citySelect.find('option').eq(0).attr 'selected', 'selected'

				else if currentCityIsResolved
					@state.set 'selectedCity', currentCityValue.name
					@state.set 'cities', [{label:currentCityValue.name, value:currentCityValue.id}]
					@ui.citySelect.find('option').eq(0).attr('selected', 'selected')

				else
					console.error 'cities loading failed', err
					fakeCitiesArray = _.clone @state.get('cities')
					fakeCitiesArray.push
						label: 'Санкт-Петербург'
						value: 0
						latitude: "59.95015089933702"
						longitude: "30.330117968749946"

					fakeCitiesArray.push
						label: 'Москва'
						value: 1
						latitude: "55.752201"
						longitude: "37.615601"

					@state.set 'cities', fakeCitiesArray
					@ui.citySelect.find('option').eq(0).attr 'selected', 'selected'

				@ui.citySelect.selectOrDie "update"

			.catch (err) =>
				console.error err
			.done =>
				@ui.citySelect.parents '.sod_select'
				.removeClass 'is-loading'
				@ui.citySelect.change()

				# start listening right after first 'selectOrDie' update, to prevent centering map on automatically selected city
				@listenTo @state, 'change:selectedCity', @onCitySelectChange

				@reload()

		onCollectionChange: =>
			@state.set 'empty', !@collection.length

		onChildviewClick: (restaurantView, model) =>
			@model.set 'restaurant_id', model.id
			@state.set
				isOrderFormVisible: true
				selectedRestaurant: model

		onShoweSlidableRegionMapClick: =>
			@state.set 'isAddressSelectVisible', true

		onCloseSlidableRegionMapClick: =>
			@state.set 'isAddressSelectVisible', false

		onShoweSlidableRegionOrderFormClick: =>
			@state.set 'isOrderFormVisible', true

		onCloseSlidableRegionOrderFormClick: =>
			@state.set 'isOrderFormVisible', false

		onCitySelectChange:  =>
			selectedCity = _.find @state.get('cities'), id: +@state.get('selectedCity')
			console.warn selectedCity
			lat = +_.get selectedCity, 'latitude', 0
			lon = +_.get selectedCity, 'longitude', 0

			@mapView.setCenter {lat,lon}
			@state.set {lat,lon} # triggers reload

		onRestaurantThumbnailClick: (e) =>
			e.stopPropagation()
			thumbNail = _.get @state.get('selectedRestaurant'), 'mainPhoto', ''
			return false unless thumbNail
			src = thumbNail.replace(/(\?.*)/, '')
			Iconto.shared.views.modals.LightBox.show
				img: src

		setTime: =>
			t = @state.get 'when_time'
			d = @state.get 'when_date'
			@model.set 'time', moment("#{d}T#{t}").unix()

		getQuery: =>
			name: @state.get('companyQuery')
			lat: @state.get 'lat'
			lon: @state.get 'lon'

		reload: =>
			super()
			.catch (err) =>
				switch err.status
					when 200005
						Iconto.shared.views.modals.PromptAuth.show
							preset: 'unauthorized'
							preventNavigate: true
							successCallback: @reload.bind @

		submitForm: =>
			restaurantName = _.get @state.get('selectedRestaurant'), 'name'
			(new @model.constructor(@model.toJSON())).save() # only POST here
			.then =>
				modal = Iconto.shared.views.modals.Alert.show
					title: "Бронь стола"
					message: "Вы успешно отправили запрос на бронь в ресторане \"#{restaurantName}\"!<br>Ждите, пожалуйста, подтверждения."
					onCancel: =>
						Iconto.shared.helpers.messages.openChat
							userId: Iconto.api.userId
							companyId: Iconto.REST.Company.mapDomainToCompanyIds Iconto.REST.Company.MAIN_COMPANY_IDS.leclick
						.then (roomView) =>
							console.warn roomView
							route = "wallet/messages/chat/#{roomView.id}"
							Iconto.shared.router.navigate route, trigger: true
						.catch (err) =>
							console.error err
				modal.$el.find('.bbm-modal__section p.text-center')
				.html(modal.model.get('message'))

			.catch (err) =>
				Iconto.shared.views.modals.ErrorAlert.show
					title: "Произошлка ошибка"
					message: "При отправке запроса на бронь столика в ресторане \"#{restaurantName}\" произошла ошибка. Попробуйте позже или выберите другой ресторан."

		onFormSubmit: (e) =>
			e.preventDefault()
			return false if @uiBlocked
#			@$('input[name=phone]').change()
			@uiBlocked = true
			@ui.submitButton.addClass 'is-loading'

			@model.set
				lat: @state.get 'lat'
				lon: @state.get 'lon'

			Iconto.api.auth()
			.then =>
				@submitForm()
			.catch (err) =>
				console.warn err
				Iconto.shared.views.modals.PromptAuth.show
					preset: 'soft'
					checkPreviousAuthorisedUser: false
					successCallback: =>
						@submitForm()
					errorCallback: =>
						console.warn 'error in auth popup'
#						Iconto.api.logout()
#						.then =>
#							Iconto.shared.router.action 'auth'
			.done =>
				@uiBlocked = false