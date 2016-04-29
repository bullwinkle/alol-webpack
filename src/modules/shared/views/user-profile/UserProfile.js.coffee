@Iconto.module 'shared.views.userProfile', (UserProfile) ->
	class UserProfile.ProfileView extends Marionette.ItemView
		className: 'user-profile-view mobile-layout'
		template: JST['shared/templates/user-profile/user-profile']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		ui:
			logoutButton: '.logout-button'
			sendConfirmationEmailButton: '.send-confirmation-email'

		events:
			'click @ui.logoutButton': 'onLogoutButtonClick'
			'click @ui.sendConfirmationEmailButton': 'sendConfirmationEmail'

		initialize: =>
			@model = new Iconto.REST.User @options.user

			inviteFriendLink = ->
				url = 'body=Привет! Попробуй http://ic.gy/1or Бронировать столики в ресторанах, заказывать такси, решать все вопросы также просто, как написать другу смс :-)'
				if Iconto.shared.helpers.device.isMobile()
					if Iconto.shared.helpers.device.isIos()
						# https://developer.apple.com/library/ios/featuredarticles/iPhoneURLScheme_Reference/SMSLinks/SMSLinks.html#//apple_ref/doc/uid/TP40007899-CH7-SW1
						url = "sms:"
					else
						url = "sms:?#{url}"
				else
					url = "mailto:?#{url}"

			@state = new Iconto.shared.models.BaseStateViewModel _.extend {}, @options,
				acceptUntrusted: !@options.user.settings.notifications.accept_untrusted
				receiveSms: @options.user.settings.notifications.receive_sms
				isMobile: Iconto.shared.helpers.device.isMobile()
				inviteFriendLink: inviteFriendLink()
				needVerification: @model.get('personal_info_status') in [Iconto.REST.User.PERSONAL_INFO_STATUS_EMPTY,
				                                                           Iconto.REST.User.PERSONAL_INFO_STATUS_CANCEL]

			@listenTo @state,
				'change:acceptUntrusted': (state, acceptUntrusted) =>
					@model.save(settings: notifications: accept_untrusted: !acceptUntrusted)
					.catch (error) =>
						console.error error
						Iconto.shared.views.modals.ErrorAlert error
					.done()
				'change:receiveSms': (state, receiveSms) =>
					@model.save(settings: notifications: receive_sms: receiveSms)
					.catch (error) =>
						console.error error
						Iconto.shared.views.modals.ErrorAlert error
					.done()

		onRender: =>
			@model.fetch()
			.then =>
				@state.set 'isLoading', false
			.catch (error) =>
				console.error error
			.done()

		sendConfirmationEmail: =>
			Iconto.api.auth()
			.then =>
				Iconto.api.post 'confirmation-email',
					success_url: "#{window.location.origin}/wallet/profile"
					error_url: "#{window.location.origin}/confirmation-error"
			.then =>
				@ui.sendConfirmationEmailButton.replaceWith '<span class="grey">Письмо отправлено</span>'
			.catch =>
				Iconto.commands.execute 'modals:auth:show'

		onLogoutButtonClick: (e) =>
			e.stopPropagation()
			Iconto.api.logout()
			.then =>
				Iconto.shared.router.action Iconto.defaultUnauthorisedRoute
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()