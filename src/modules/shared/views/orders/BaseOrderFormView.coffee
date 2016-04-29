Iconto.module 'shared.views.orders', (Orders) ->

	class OrderFormModel extends Backbone.Model

	class Orders.BaseOrderFormView extends Marionette.ItemView
		template: JST['shared/templates/orders/order-form-taxi']
		className: 'form-view taxi'

		ui:
			form: 'form'

		events:
			'submit form': 'onFormSubmit'

		modelEvents: {}

		behaviors:
			Epoxy: {}
			Form: {}
#				submit: 'button.submit-button'
#				events:
#					click: 'button.submit-button'

		initialize: ->
			@state = new Iconto.shared.models.BaseStateViewModel()
			@model = new OrderFormModel @options

		onRender: =>

		onFormSubmit: (e) =>
			e.preventDefault()

			submitedObject =
				formData: @ui.form.serializeObject()

			console.log submitedObject

			submitedObject
