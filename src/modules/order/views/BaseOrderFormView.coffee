Iconto.module 'order.views', (Order) ->

	class OrderFormModel extends Backbone.Model

	class Order.BaseOrderFormView extends Marionette.LayoutView
		template: JST['shared/templates/orders/order-form-taxi']
		className: 'form-view taxi'

		ui:
			form: 'form'

		events: {}
#			'submit form': 'onFormSubmit'

		modelEvents: {}

		behaviors:
			Epoxy: {}
			Form:
				events:
					submit: 'form'

		initialize: ->
			@state = new Iconto.shared.models.BaseStateViewModel()
			@model = new OrderFormModel @options

		onRender: =>

		onFormSubmit: (e) =>
			e.preventDefault()

			submitedObject =
				formData: @ui.form.serializeObject()
			submitedObject
