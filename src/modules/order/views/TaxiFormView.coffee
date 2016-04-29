Iconto.module 'order.views', (Order) ->

	GEOCODE_BASE_URL = 'https://maps.googleapis.com/maps/api/geocode/json'

	inherit = Iconto.shared.helpers.inherit

	class Order.TaxiFormView extends Marionette.LayoutView
		template: JST['order/templates/order-form-taxi']
		className: 'order-view taxi mobile-layout'

		behaviors:
			Layout: {}
			Epoxy: {}
			Form:
				submit: 'button.submit-button'
				events:
					submit: 'form'

		ui:
			form: 'form'
			carTypeInput: '.car-type'
			showFromMapButton: '.show-map-button-from'
			showWhereMapButton: '.show-map-button-where'
			closeMapButton: '.close-map'
			addComment: '.add-comment'
			submitButton: 'button.submit-button'
			labelForStandart: '[for=standart]'
			labelForVip: '[for=vip]'
			mapRegion: '.map-region'
			googleMapContainer: '.google-map-container'
			citySelect: 'select.city-select'
			mapAddressInputWrapper: '.map-region .with-loader'
			tobarLeftButton: '.topbar-region .left-small'

		events:
			'input': 'onInput'
			'click @ui.addComment': 'onCommentToggleClick'
			'click @ui.labelForStandart': 'onLabelForStandartClick'
			'click @ui.labelForVip': 'onLabelForVipClick'
			'click @ui.showFromMapButton': 'onShowFromMapButton'
			'click @ui.showWhereMapButton': 'onShowWhereMapButton'
			'click @ui.closeMapButton': 'onCloseMapButtonClick'
			'click @ui.tobarLeftButton': 'onTobarLeftButtonClick'

		regions:
			mapRegion: '.map-region'

		validated: =>
			model: @model
			state: @state

		bindingSources: =>
			model: @model
			state: @state

		initialize: ->
			state = if @options.state and @options.state instanceof Backbone.Model then @options.state.toJSON() else {}
			_.extend state,
				topbarTitle: "Заказ такси"
				# topbarLeftButtonClass: ""
				# topbarLeftButtonSpanClass: "ic-chevron-left"
				mapBiningFieldName: 'whereAddress' # field, exesting in model, where to pass results, selected in map
				mapInputValue: ''
				cities: []
				isLoading: false
				isMapShowen: false
				isSubmitting: false
				isCommentAreaVisible: false

			@state = new Iconto.shared.models.BaseStateViewModel state

			delete @options.state
			_.extend @options, Iconto.shared.helpers.navigation.getQueryParams()
			@model = new Iconto.order.models.TaxiOrderModel()
			unless @options.currentCity then @options.currentCity = ''
			@model.set @options

			@listenTo @state,
				'change:isMapShowen': (state, isMapShowen, options) =>
					if isMapShowen then @onMapShow()
					else @onMapClose()

			@listenTo iContoApplication, 'iOS-bridge', @setIcontoBringe
			Iconto.api.connect()

		onRender: =>
			now = moment()
			nowDate = now.format('YYYY-MM-DD')
			nowTime = now.add(15,'minutes').format('HH:mm')

			newAttributes = {}
			newAttributes.when_time = nowTime
			newAttributes.when_date = nowDate
			newAttributes.phone = (@options.phone || _.get(Iconto,'api.currentUser.phone','')) + ''
			@model.set newAttributes

			if window.App?.getGoogleMap
				window.App.getGoogleMap().then @initGoogleMap

			unless @model.get('company_id')
				Iconto.shared.views.modals.ErrorAlert.show
					title: 'Ошибка'
					message: 'Отсутствует идентификатор компании'

			@state.set isLoading:false

			Iconto.shared.services.geo.getCurrentPosition()
			.then (geo) =>
				@state.set 'coords',
					lat: geo.coords.latitude
					lon: geo.coords.longitude

				citiesPromise = (new Iconto.REST.CityCollection()).fetch
					country_id: 6
					limit: 100

				currentCityPromise = (new Iconto.REST.City()).fetch
					lat: geo.coords.latitude
					lon: geo.coords.longitude

				Q.settle [citiesPromise,currentCityPromise]
				.then ([cities, currentCity]) =>
					citiesValue = cities.value()
					citiesIsResolved = cities.isResolved()

					currentCityValue = currentCity.value().items[0]
					currentCityIsResolved = currentCity.isResolved()

					all = citiesIsResolved and currentCityIsResolved
					any = citiesIsResolved or currentCityIsResolved
					noOne = !citiesIsResolved and !currentCityIsResolved

					if all
						@model.set 'currentCity', currentCityValue.name
						currentCityIndex = 0
						@state.set 'cities', citiesValue.map (city, index, cities) =>
							if city.id is currentCityValue.id then currentCityIndex = index
							label: city.name
							value: city.id

						@ui.citySelect.find('option').eq(currentCityIndex).attr 'selected', 'selected'
						@ui.citySelect.selectOrDie "update"

					else if citiesIsResolved
						cities = citiesValue.map (city, index, cities) =>
							label: city.name
							value: city.id
						cities.unshift
							label: 'Выберите город'
							value: ''
						@state.set 'cities', cities
						@ui.citySelect.find('option').eq(0).attr 'selected', 'selected'
						@ui.citySelect.selectOrDie "update"

					else if currentCityIsResolved
						@model.set 'currentCity', currentCityValue.name
						@state.set 'cities', [{label:currentCityValue.name, value:currentCityValue.id}]
						@ui.citySelect.find('option').eq(0).attr 'selected', 'selected'
						@ui.citySelect.selectOrDie "update"

					else
						console.error 'cities loading faild', err
						fakeCitiesArray = _.clone @state.get('cities')
						fakeCitiesArray.push
							label: 'Санкт-Петербург'
							value: 0
						fakeCitiesArray.push
							label: 'Москва'
							value: 1

						@state.set 'cities', fakeCitiesArray
						@ui.citySelect.find('option').eq(0).attr 'selected', 'selected'
						@ui.citySelect.selectOrDie "update"

				.done =>
					@ui.citySelect.parents '.sod_select'
					.removeClass 'is-loading'
					@ui.citySelect.change()

		onShow: =>
			@ui.citySelect.parents '.sod_select'
			.addClass 'is-loading'

			@setIcontoBringe()

#		onTobarLeftButtonClick: =>
#			defaultRoute = "/wallet/cards"
#			parsedUrl = Iconto.shared.helpers.navigation.parseUri()
#			fromRoute = _.get parsedUrl, 'query.from'
#			route = fromRoute or defaultRoute
#			Iconto.shared.router.navigate route, trigger: true

		getAddressString: (coords) =>
			lat = coords.latitude
			lon = coords.longitude
			Iconto.api.get("#{ICONTO_API_URL}location/?lat=#{lat}&lng=#{lon}")

		setIcontoBringe: (iContoBridge=null) =>
			iContoBridge = iContoBridge or window.__iContoBridge or null
			@state.set 'iContoBridge', iContoBridge if iContoBridge

		onBeforeDestroy: =>
			@stopListening iContoApplication, 'iOS-bringe'

		onCommentToggleClick: =>
			@state.set 'isCommentAreaVisible', !@state.get 'isCommentAreaVisible'

		onLabelForStandartClick: =>
			@$ "##{@ui.labelForStandart.attr('for')}"
			.click()

		onLabelForVipClick: =>
			@$ "##{@ui.labelForVip.attr('for')}"
			.click()

		sendMessage: (messagBody) =>
			roomView = new Iconto.REST.RoomView()
			reasons = []
			userId = Iconto.api.userId
			companyId = @model.get('company_id') or Iconto.REST.Company.mapDomainToCompanyIds Iconto.REST.Company.MAIN_COMPANY_IDS.taxi

			unless companyId
				return Iconto.shared.views.modals.Alert.show
					title: 'Произошла ошибка'
					message: 'Нет доступа'

			reasons.push {type: Iconto.REST.Reason.TYPE_USER, user_id: userId}
			reasons.push {type: Iconto.REST.Reason.TYPE_COMPANY, company_id: companyId}

			roomView.save(reasons: reasons)
			.then (roomView) =>
				message = new Iconto.REST.Message
					body: messagBody
					room_view_id: roomView.id
					attachments: []
					type: Iconto.REST.Message.PRODUCER_TYPE_USER

				message.save()

		onShowFromMapButton: (e) =>
			@state.set
				'mapBiningFieldName': 'fromAddress'
				'isMapShowen': true

		onShowWhereMapButton: =>
			@state.set
				'mapBiningFieldName': 'whereAddress'
				'isMapShowen': true

		onCloseMapButtonClick: =>
			@state.set 'isMapShowen', false

		onMapShow: =>
			# nothing here

		onMapClose: =>
			key = @state.get('mapBiningFieldName')
			val = @state.get('mapInputValue')
			@model.set key, val

		submitForm: (submittedObject) =>
			model = @model.toJSON()

			# format message
			model.fromAddress or model.fromAddress  = "Не указано"
			model.whereAddress or model.whereAddress  = "Не указано"
			model.when_time or model.when_time  = "Не указано"
			submittedObject.now = new Date()

			submittedObject.formattedMessage = """
				Телефон: 		#{ model.phone }
				Город:			#{ model.currentCity or 'не указан' }
				Откуда: 		#{ model.fromAddress }
				Куда: 			#{ model.whereAddress }
				Когда подать: 	#{ model.when_date} в #{model.when_time }
				Тип авто:		#{ model.car_type }
				Комментарий: 	#{ model.comment }
			"""

			@sendMessage(submittedObject.formattedMessage)
			.then (message) =>
				@state.set 'isSubmitting', false
				waitFor = 3 #sec
				deffer = =>
					if waitFor
						@ui.submitButton.text "Подождите #{waitFor} сек."
						waitFor--
					else
						clearInterval interval
						unless @notifyIos 'form-submit'
							route = "/wallet/messages/chat/#{message.room_view_id}"
							Iconto.shared.router.navigate route, trigger: true
				deffer()
				interval = setInterval deffer, 1000
			.dispatch(@)
			.catch (error) =>
				console.error error
				@state.set 'isSubmitting', false
				Iconto.shared.views.modals.ErrorAlert.show error

		onFormSubmit: (e) =>
			e.preventDefault()
			return false if @state.get('isSubmitting')

			submittedObject =
				formData: @ui.form.serializeObject()

			@state.set 'isSubmitting', true
			@$('input[name=phone]').change()

			Iconto.api.auth()
			.then =>
				@submitForm submittedObject
			.catch (err) =>
				console.error err
				Iconto.shared.views.modals.PromptAuth.show
					preset: 'soft'
					checkPreviousAuthorisedUser: false
					successCallback: =>
						@submitForm submittedObject
					errorCallback: =>
						@state.set 'isSubmitting', false
#			.done =>
#				@state.set 'isSubmitting', false

		initGoogleMap: =>
			promise = new Promise (resolve,reject) =>
				stateCoords = @state.get('coords')
				if stateCoords?.lat and stateCoords?.lon
					resolve coords:
						latitude: stateCoords.lat
						longitude: stateCoords.lon
				else
					Iconto.shared.services.geo.getCurrentPosition()
					.then resolve
					.catch reject

			promise
			.then (geo) =>
				geocoder = new google.maps.Geocoder()
				latlng = new google.maps.LatLng geo.coords.latitude, geo.coords.longitude

				gMap = new google.maps.Map @ui.googleMapContainer[0],
				# https://developers.google.com/maps/documentation/javascript/3.exp/reference?hl=ru#MapOptions

					zoom: 10
					center: latlng
					disableDefaultUI: true
#					noClear: true

				currentPositionMarker = new google.maps.Marker
					position: latlng
					map: gMap
					title: 'Вы здесь'

				@ui.centerMarker = $('<div class="map-marker center"></div>').appendTo @ui.googleMapContainer

				onGoogleMapDrug = =>
					if !@ui.centerMarker.hasClass 'is-raised'
						@ui.centerMarker.addClass 'is-raised'

				onGoogleMapDrugEnd = =>
					if @ui.centerMarker.hasClass 'is-raised'
						@ui.centerMarker.removeClass 'is-raised'

				timeout1 = 0
				timeout2 = 0
				onGoogleMapIdle = =>
					return false unless @state.get 'isMapShowen'
					if @ui.centerMarker.hasClass 'is-raised'
						@ui.centerMarker.removeClass 'is-raised'

					centerPoint = gMap.getCenter()
					@ui.mapAddressInputWrapper.addClass 'is-loading'

					geocoder.geocode 'location': centerPoint,  (results, status) =>
						switch status
							# when "OK" # indicates that no errors occurred; the address was successfully parsed and at least one geocode was returned.
							# when "ZERO_RESULTS" # indicates that the geocode was successful but returned no results. This may occur if the geocoder was passed a non-existent address.
							when "OVER_QUERY_LIMIT" # indicates that you are over your quota, need to try one more some later, maybe one sec.
								clearTimeout timeout1
								return timeout1 = setTimeout onGoogleMapIdle, 1000
							# when "REQUEST_DENIED" # indicates that your request was denied.
							# when "INVALID_REQUEST" # generally indicates that the query (address, components or latlng) is missing.
							# when "UNKNOWN_ERROR" # indicates that the request could not be processed due to a server error. The request may succeed if you try again.

						result = if results?[0] then results[0] else {formatted_address: 'не определено'}
						address = result.formatted_address
						defer = =>
							@state.set 'mapInputValue', address
							@ui.mapAddressInputWrapper.removeClass 'is-loading'
						clearTimeout timeout2
						timeout2 = setTimeout defer, 100

				google.maps.event.addListener gMap, 'drag', onGoogleMapDrug
				google.maps.event.addListener gMap, 'dragend', onGoogleMapDrugEnd
				google.maps.event.addListener gMap, 'idle', onGoogleMapIdle

		notifyIos: (event='', data=null) =>
			return console.error('notifyIos needs event name') unless event
			iosBridge = if window.__iContoBridge
				window.__iContoBridge
			else if @state.get('iContoBridge')
				@state.get('iContoBridge')
			else null

			unless iosBridge?.notify
				return false
			else
				iosBridge.notify event, {data}
				return true