@Iconto.module 'office.views.messages', (Messages) ->
	class SettingsModel extends Backbone.Epoxy.Model
		defaults:
			sms_delivery: false
			sms_schedule: false

	class Messages.SettingsView extends Marionette.ItemView
		className: 'settings-view mobile-layout with-bottombar'
		template: JST['office/templates/messages/settings/settings']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
				outlets:
					bottombar: JST['office/templates/messages/bottombar']

		ui:
			topbarRightButton: '.topbar-region .right-small'

		events:
			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'

		modelEvents:
			'validated:valid': ->
				@state.set 'modelIsValid', true
			'validated:invalid': ->
				@state.set 'modelIsValid', false

		serializeData: =>
			state: @state.toJSON()

		initialize: =>
			@model = new SettingsModel()
			@companyModel = new Iconto.REST.Company(id: @options.companyId)

			@state = new Iconto.office.models.StateViewModel @options
			@state.set
				topbarTitle: 'Настройки рассылок'
				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal, leadingComma: true)}"
				topbarRightButtonSpanText: 'Сохранить'
				topbarRightButtonClass: 'text-button'

			@state.addComputed 'topbarRightButtonDisabled',
				deps: ['isSaving', 'modelIsValid'],
				get: (isSaving, modelIsValid) =>
					isSaving or not modelIsValid

		onRender: =>
			Backbone.Validation.bind @

			@companyModel.fetch()
			.then (company) =>
				@model.set
					sms_delivery: company.settings.notifications['sms_delivery']
					sms_schedule: company.settings.notifications['sms_schedule']
				@state.set
					isLoading: false
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onTopbarRightButtonClick: =>
			@state.set 'isSaving', true

			query =
				'sms_delivery': @model.get 'sms_delivery'
				'sms_schedule': @model.get 'sms_schedule'
			settings = _.extend {}, @options.company.settings, notifications: query

			@companyModel.save(settings: settings)
			.then =>
				Iconto.shared.views.modals.Alert.show
					title: 'Сохранено'
					message: 'Изменения успешно сохранены'
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set
					isSaving: false
					modelIsValid: false