Iconto.module 'shared.views.orders', (Orders) ->

	inherit = Iconto.shared.helpers.inherit

	class TaxiOrderModel extends Backbone.Model
		defaults:
			phone: ""
			from: ""
			when_time: ""
			when_date: ""
			where: ""
			car_type: "standart"

		validation:
			phone:
				required: true
				minLength: 7
				maxLength: 200

			from:
				required: true
				minLength: 3
				maxLength: 200

			when_time:
				required: false

			when_date:
				required: false

			where:
				required: true
				minLength: 3
				maxLength: 200

			car_type:
				required: false

	_.extend TaxiOrderModel::,Backbone.Validation.mixin

	class Orders.TaxiFormView extends Orders.BaseOrderFormView
		template: JST['shared/templates/orders/order-form-taxi']
		className: 'form-view taxi'

		behaviors: inherit Orders.BaseOrderFormView::behaviors,
			Form:
				submit: 'button.submit-button'
				events:
					click: 'button.submit-button'

		ui: inherit Orders.BaseOrderFormView::ui,
			carTypeInput: '.car-type'
			getLocationButton: '.get-location-button'

		events:  inherit Orders.BaseOrderFormView::events,
			'input': 'onInput'
			'click @ui.getLocationButton': 'onGetAddressStringButtonClick'

		modelEvents: inherit Orders.BaseOrderFormView::modelEvents
#			'validated': (bolean,model, props) =>
#				console.info 'is valid', bolean, props

		validated: =>
			model: @model

		initialize: ->
			@state = new Iconto.shared.models.BaseStateViewModel()
			@model = new TaxiOrderModel @options

			@listenTo iContoApplication, 'iOS-bridge', @loadDataFromIos

		onRender: =>
			super()

			now = moment()
			nowDate = now.format('YYYY-MM-DD')
			nowTime = now.add(15,'minutes').format('HH:mm')

			@model.set
				when_time: nowTime
				when_date: nowDate

			@loadDataFromIos()

		onGetAddressStringButtonClick: (e) =>
			@ui.getLocationButton.addClass 'is-loading'
			Iconto.shared.services.geo.getCurrentPosition()
			.then (geo) =>
				if geo.coords.latitude and geo.coords.longitude
					@getAddressString(geo.coords)
					.then (res) =>
						if res.data?.address and res.data?.address.length > 5
							@model.set 'from', res.data.address
						else
							@ui.getLocationButton.removeClass 'is-loading'
							throw 'faild to define address'
					.catch (err) =>
						throw err
					.done =>
						@ui.getLocationButton.removeClass 'is-loading'
			.catch (err) =>
				console.error err
				@ui.getLocationButton.removeClass 'is-loading'
			.done()

		getAddressString: (coords) =>
			lat = coords.latitude
			lon = coords.longitude
			Iconto.api.get("#{ICONTO_API_URL}location/?lat=#{lat}&lng=#{lon}")

		loadDataFromIos: (iContoBridge=null) =>
			iosBridge = if iContoBridge
				iContoBridge
			else if window.__iContoBridge
				window.__iContoBridge
			else
				null

			if iosBridge?.user?.phone
				@model.set 'phone', iosBridge.user.phone


		onBeforeDestroy: =>
			@stopListening App, 'iOS-bringe'

		onFormSubmit: (e) =>
			submitedObject = super(e)
			model = @model.toJSON()

			# format message
			model.from or model.from  = "Не указано"
			model.where or model.where  = "Не указано"
			model.when_time or model.when_time  = "Не указано"
			submitedObject.now = new Date()
			submitedObject.formattedMessage = """
				Телефон: #{model.phone}
				Откуда: #{model.from}
				Куда: #{model.where}
				Когда подать: #{model.when_date} в #{model.when_time}
				Тип авто: #{ model.car_type }
			"""

			if @model.isValid()

				if __iContoBridge?.notify
					__iContoBridge.notify 'form-submit',
						data: submitedObject