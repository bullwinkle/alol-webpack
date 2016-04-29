@Iconto.module 'shared.views.userProfile.verification', (Verification) ->
	class Verification.ConfirmationView extends Marionette.ItemView
		className: 'verification-confirmation-view mobile-layout'
		template: JST['shared/templates/user-profile/verification/confirmation']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		ui:
			getCodeButton: '[name=get-code-button]'
			continueButton: '[name=continue-button]'
			codeInput: 'input[name=code-input]'

		events:
			'click @ui.getCodeButton': 'onGetCodeButtonClick'
			'click @ui.continueButton': 'onContinueButtonClick'

		initialize: =>
			@model = new Iconto.REST.User(@options.user)

			# [wallet|office]/profile
			@page = Backbone.history.fragment.split('/').slice(0, 2).join('/')

			@state = new Iconto.shared.models.BaseStateViewModel _.extend {}, @options,
				isLoading: false
				topbarTitle: 'Подтверждение телефона'
				breadcrumbs: [
					{title: 'Профиль', href: "/#{@page}"}
					{title: 'Подтверждение телефона', href: document.location.pathname}
				]
				codeInputHidden: true

		onGetCodeButtonClick: =>
			@ui.getCodeButton.addClass('is-loading').prop('disabled', true)

			Iconto.api.post('confirmation-code', event: 'on_phone_confirmation')
			.then (response) =>
				Iconto.shared.views.modals.Alert.show
					message: 'Вам выслано SMS с кодом подтверждения.'
					submitButtonText: 'Продолжить'
					onCancel: =>
						@state.set codeInputHidden: false
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@ui.getCodeButton.removeClass('is-loading').prop('disabled', false)

		onContinueButtonClick: =>
			@ui.continueButton.addClass('is-loading').prop('disabled', true)

			Iconto.api.put('confirmation-code', {event: 'on_phone_confirmation', code: @ui.codeInput.val().trim()})
			.then (response) =>
				Iconto.shared.views.modals.Alert.show
					message: 'Телефон успешно подтвержден.'
					submitButtonText: 'Продолжить'
					onCancel: =>
						@state.set codeInputHidden: false
						# invalidate for user personal_phone_status to take effect
						@model.invalidate()
						Iconto.shared.router.navigate "#{@page}/verification", trigger: true
			.dispatch(@)
			.catch (error) =>
				console.error error
				error.msg = switch error.status
					when 202107 then 'Неверный код подтверждения.'
					else
						error.msg
				Iconto.shared.views.modals.ErrorAlert.show error
				console.log error
			.done =>
				@ui.continueButton.removeClass('is-loading').prop('disabled', false)