Iconto.module 'order.views', (Order) ->

	class Order.BookedRestaurantEditView extends Marionette.ItemView
		template: JST['order/templates/restaurant/booked-restaurant-edit']
		className: 'order-form-container l-p-20 t-a-left s-bg-white'
		behaviors:
			Epoxy: {}
			Form:
				validated: ['model']
				submit: 'button.submit-button'
				events:
					submit: 'form'
		ui:
			submitButton: '.submit-button'
			deleteButton: '.delete'

		events:
			'click @ui.deleteButton': 'onDeleteButtonClick'

		bindingSources: ->
			state: @state
			restaurant: @restaurant

		initialize: ->
			@state = new Iconto.shared.models.BaseStateViewModel
				when_date: moment.unix(@model.get('time_at')).format('YYYY-MM-DD')
				when_time: moment.unix(@model.get('time_at')).format('HH:mm')
				restaurant: null
			@restaurant = new Iconto.REST.LeclickRestaurant id: @model.get 'restaurant_id'

		onRender: =>
			@restaurant.fetch()

		onDeleteButtonClick: =>
			@model.destroy()
			.then =>
				@destroy()
			.catch (err) =>
				console.error err

		submitForm: =>
			restaurantName = @model.get('restaurant_id')

			(new @model.constructor(@model.toJSON())).save() # only POST here
			.then =>
				@destroy()

			.catch (err) =>
				Iconto.shared.views.modals.ErrorAlert.show
					title: "Произошлка ошибка"
					message: "При отправке запроса на бронь столика в ресторане \"#{restaurantName}\" произошла ошибка. Попробуйте позже или выберите другой ресторан."

		onFormSubmit: (e) =>
			e.preventDefault()
			return false if @uiBlocked
			@uiBlocked = true
			@ui.submitButton.addClass 'is-loading'

			@model.set
				lat: @state.get 'lat'
				lon: @state.get 'lon'
				time_at: +moment("#{@state.get('when_date')}T#{@state.get('when_time')}", "YYYY-MM-DDTHH:mm").unix()

			Iconto.api.auth()
			.then =>
				@submitForm()
			.catch (err) =>
				console.error err
				Iconto.shared.views.modals.PromptAuth.show
					preset: 'soft'
					checkPreviousAuthorisedUser: false
					successCallback: => @submitForm()
					errorCallback: =>
						console.warn 'error in auth popup'
			.done =>
				@uiBlocked = false

	class Order.BookedRestaurantListItem extends Marionette.ItemView
		tagName: 'li'
		className: 'button list-item menu-item restaurant-item l-pr-10 l-pl-10'
		template: JST['order/templates/restaurant/restaurant-booked-item']
		events:
			'click': 'onClick'
		initialize: ->
		onClick: =>
			Iconto.shared.views.modals.LightBox.show
				view: Order.BookedRestaurantEditView
				options: @options
			.$el.addClass 'iconto-office-layout'

	class Order.BookedRestaurants extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
		template: JST['order/templates/restaurant/booked-restaurants']
		className: 'booked-reastaurants mobile-layout'
		childView: Order.BookedRestaurantListItem
		childViewContainer: '.list'
		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
#			InfiniteScroll:
#				scrollable: '.list'

		initialize: ->
			@state = new Iconto.shared.models.BaseStateViewModel
				topbarTitle: 'Борни столиков'
			@collection = new Iconto.REST.LeclickReserveCollection()

		onRender: =>
			@state.set 'isLoading', false
			@reload()

		getQuery: =>
			find: 'all'

		reload: =>
			super()
			.catch (err) =>
				switch err.status
					when 200005
						Iconto.shared.views.modals.PromptAuth.show
							preset: 'unauthorized'
							preventNavigate: true
							successCallback: @reload.bind @
