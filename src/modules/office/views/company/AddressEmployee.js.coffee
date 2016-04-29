@Iconto.module 'office.views.company', (Company) ->
	class Company.AddressEmployeeView extends Marionette.ItemView
		template: JST['office/templates/company/address-employee']
		className: 'company-address-employee'

		ui:
			tips: '.has-tip'

		behaviors:
			Epoxy: {}
			ValidatedForm: {}

		bindings:
			"[name=last_name]": "value:last_name, events: ['paste', 'input']"
			"[name=first_name]": "value:first_name, events: ['paste', 'input']"
			"[name=phone]": "value:state_phone, events: ['paste', 'input']"
			"[name=send_sms]": "checked:send_sms"

		events:
			'click @ui.tips': 'onTipsClick'

		initialize: =>
			@model = new Iconto.REST.Contact
				position_type: Iconto.REST.Contact.POSITION_TYPE_ADDRESS_EMPLOYEE
				address_id: @options.addressId

			@model.validation.email.required = false

			@state = new Backbone.Model phone: ''
			@listenTo @state, 'change:phone', (model, value) =>
				value = Iconto.shared.helpers.phone.parse value
				@model.set 'phone', "7#{value}", validate: true

		onTipsClick: (e) =>
			$tip = $(e.currentTarget)
			Iconto.shared.views.modals.Alert.show
				message: $tip.data('message')