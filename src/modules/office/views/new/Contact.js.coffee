@Iconto.module 'office.views.new', (New) ->
	class New.ContactView extends Marionette.ItemView
		template: JST['office/templates/new/contact']
		className: 'contact-view mobile-layout'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
			Form:
				submit: '[name=continue-button]'
				events:
					click: '[name=continue-button]'

		ui:
			backButton: '[name=back-button]'
			continueButton: '[name=continue-button]'
			useMyInfoCheckbox: 'input[type=checkbox]'
			phonePrefix: '.phone-prefix'

		events:
			'click @ui.backButton': 'onBackButtonClick'
			'change @ui.useMyInfoCheckbox': 'onUseMyInfoCheckboxChange'

		serializeData: =>
			@model.toJSON()
			@state.toJSON()

		validated: =>
			model: @model

		initialize: =>
			@model = @options.contact
			@buffer = new Iconto.REST.Contact @options.contact.toJSON()

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Заявка на управление компанией'
				isLoading: false
				step: 5
				stepIcons: @options.stepIcons

				phone: ''

			@listenTo @state, 'change:phone', (model, value) =>
				@model.set 'phone', "7#{Iconto.shared.helpers.phone.parse(value)}"#, validate: true

		onRender: =>
			@state.set phone: @model.get('phone').substr(1, @model.get('phone').length - 1)

			if @model.get('id')
				@ui.useMyInfoCheckbox.prop('checked', true)
				@$('input[type^=te]').prop('disabled', true)

			@ui.continueButton.click()

		onBackButtonClick: =>
			@trigger 'transition:back'

		onFormSubmit: =>
			@trigger 'transition:submitRequest'

		onUseMyInfoCheckboxChange: (e) =>
			checked = e.currentTarget.checked
			@$('input[type^=te]').prop('disabled', checked)
			@ui.phonePrefix[if checked then 'addClass' else 'removeClass']('disabled')

			if checked
				contact = _.pick @options.user.toJSON(), 'first_name', 'last_name', 'phone', 'email'
				@state.set phone: contact.phone.substr(1, contact.phone.length - 1)
				@model.set contact, validate: true
			else
				@state.set phone: ''
				@model.set (new Iconto.REST.Contact()).toJSON()