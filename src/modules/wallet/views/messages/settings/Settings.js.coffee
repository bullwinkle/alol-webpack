@Iconto.module 'wallet.views.messages', (Messages) ->
	class SettingsModel extends Backbone.Epoxy.Model
		defaults:
			accept_untrusted: false

	class Messages.SettingsView extends Marionette.ItemView
		className: 'settings-view mobile-layout with-bottombar'
		template: JST['wallet/templates/messages/settings/settings']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
				outlets:
					bottombar: JST['wallet/templates/messages/bottombar']

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
			@userModel = new Iconto.REST.User(id: 'current')

			@state = new Iconto.wallet.models.StateViewModel @options
			@state.set
				topbarTitle: 'Настройки рассылок'
				topbarRightButtonSpanText: 'Сохранить'
				topbarRightButtonClass: 'text-button'

			@state.addComputed 'topbarRightButtonDisabled',
				deps: ['isSaving', 'modelIsValid'],
				get: (isSaving, modelIsValid) =>
					isSaving or not modelIsValid

		onRender: =>
			Backbone.Validation.bind @

			@userModel.fetch()
			.then (user) =>
				@model.set
					accept_untrusted: user.settings.notifications['accept_untrusted']
				@state.set
					isLoading: false
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onTopbarRightButtonClick: =>
			@state.set 'isSaving', true

			query =
				'accept_untrusted': @model.get 'accept_untrusted'
			settings = _.extend {}, @options.user.settings, notifications: query

			@userModel.save(settings: settings)
			.then =>
				Iconto.shared.views.modals.Alert.show
					title: 'Сохранено'
					message: 'Настройки успешно сохранены.'
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set
					isSaving: false
					modelIsValid: false