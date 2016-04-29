@Iconto.module 'office.views.index', (Index) ->
	class Index.CompanyContactView extends Marionette.ItemView
		template: JST['office/templates/company/contact']
		className: 'contact-view'

		bindings:
			"[name=last_name]": "value:last_name, events: ['change', 'paste', 'input']"
			"[name=first_name]": "value:first_name, events: ['change', 'paste', 'input']"
			"[name=email]": "value:email, events: ['change', 'paste', 'input']"
			"[name=phone]": "value:state_phone, events: ['change', 'paste', 'input']"
			"[name=send-sms]": "checked:state_sendSms"

		behaviors:
			Epoxy: {}
			Form:
				submit: '[name=save-button]'
				events:
					click: '[name=save-button]'

		validated: =>
			model: @model

		initialize: =>
			@model = new Iconto.REST.Contact _.extend position_type: 0, @options

			@listenTo @model,
				'validated': =>
					_.extend @setterOptions, validate: true
				'contact:saved': =>
					_.extend @setterOptions, validate: false
					@state.set phone: '', sendSms: false, validate: false

			@state = new Backbone.Model
				phone: @model.get('phone')
				sendSms: false

			@listenTo @state,
				'change:phone': (model, value) =>
					@model.set phone: "7#{Iconto.shared.helpers.phone.parse(value)}", { validate: (@setterOptions.validate || false) }
				'change:sendSms': (model, value) =>
					@model.set send_sms: value