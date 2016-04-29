@Iconto.module 'feedback.views', (Feedback) ->
	class Feedback.FeedbackView extends Marionette.ItemView
		template: JST['feedback/templates/feedback']
		className: 'feedback-page'

		behaviors:
			Epoxy: {}

		ui:
			textarea: 'textarea'
			sendButton: '.button-send'
			sendSuccess: '.send-success'

		events:
			'click .signup': 'onSignupClick'
			'click .signin': 'onSigninClick'
			'click @ui.sendButton': 'onButtonSendClick'
			'click .button-register': 'onButtonRegisterClick'
			'click .button-authorize': 'onButtonAuthorizeClick'

			'input .phone-input-field': 'onPhoneInput'
			'keyup .phone-input-field': 'onPhoneKeyup'

			'input .password-authorize-input': 'validateLoginPassword'
			'keyup .password-authorize-input': 'onLoginPasswordAuthorizeKeyup'

			'input .phone-authorize-input': 'validateLoginPassword'
			'keyup .phone-authorize-input': 'onLoginPasswordAuthorizeKeyup'

#			'click .cashback-modal': 'onCashbackModalClick'

		initialize: =>
			@spot = new Iconto.REST.AddressSpot(id: @options.addressSpotId)

			@state.set
				companyImageUrl: Iconto.shared.helpers.image.resize(@options.company.image.url)
				isAuthorized: @options.user?
				userId: @options.user?.id

		setButtonLoading: (button, loading) =>
			button[if loading then 'attr' else 'removeAttr']('disabled', true)

		onRender: =>
			@spot.fetch()
			.dispatch(@)
			.catch (error) =>
				console.error error
			.done()

		onButtonSendClick: =>
			if @ui.sendButton.text() is 'НАПИСАТЬ ЕЩЕ'
				@ui.textarea.val('').removeClass('opacity0')
				@ui.sendButton.text('ОТПРАВИТЬ')
				@ui.sendSuccess.addClass('opacity0')
			else
				$message = @ui.textarea.val().trim()

				if $message
					@setButtonLoading(@ui.sendButton, true)

					if @state.get('isAuthorized')

						Iconto.ws.connect()
						.then =>
							roomView = new Iconto.REST.RoomView()

							reasons = [
								{type: Iconto.REST.Reason.TYPE_USER, user_id: @state.get('userId')}
								{type: Iconto.REST.Reason.TYPE_ADDRESS, address_id: @spot.get('address_id')}
							]

							attachments = [
								type: 'ATTACHMENT_TYPE_SPOT'
								spot:
									id: @spot.get('id')
									name: @spot.get('description')
							]

							roomView.save(reasons: reasons)
							.then (response) =>
								message = new Iconto.REST.Message
									body: $message
									room_view_id: response.id
									attachments: attachments
								message.save()
								.then =>
									setTimeout ->
										Iconto.shared.router.navigate "wallet/messages/chat/#{response.id}", trigger: true
									, 1000
							.dispatch(@)
							.catch (error) =>
								console.error error
								error.msg = switch(error.status)
									when 'INTERNAL_ERROR'
										"Произошла ошибка, попробуйте отправить сообщение позже"
									else
										error.msg
								Iconto.shared.views.modals.ErrorAlert.show error
								@setButtonLoading(@ui.sendButton, false)
							.done()
					else
						addressSpotRequest = new Iconto.REST.AddressSpotReview
							review: $message
							is_public: false
							hash: @spot.get('id')

						addressSpotRequest.save()
						.then =>
							@ui.textarea.addClass('opacity0')
							@ui.sendSuccess.removeClass('opacity0')
							@ui.sendButton.text('НАПИСАТЬ ЕЩЕ')
						.catch (error) =>
							console.error error
							Iconto.shared.views.modals.ErrorAlert.show error
						.done =>
							@setButtonLoading(@ui.sendButton, false)
				else
					@ui.textarea.focus()

		onSignupClick: =>
			# wanna register
			@$('.bubble').removeClass('authorization').addClass('registration')
			@$('.phone-input-field').val('').focus()
			@$('.registration-hint').text('')

		onSigninClick: =>
			# wanna login
			@$('.bubble').removeClass('registration').addClass('authorization')
			@$('.phone-authorize-input').val('').focus()
			@$('.password-authorize-input').val('')
			@$('.authorization-hint').text('')

		onButtonRegisterClick: =>
			# set button loading
			@setButtonLoading(@$('.button-register'), true)

			# phone trim
			phone = @$('.phone-input-field').val().trim().replace(/[\(,\),\-, ]+/g, '')

			# try create user
			(new Iconto.REST.User()).save(login: '7' + phone)
			.then =>
				@$('.bubble').removeClass('registration').addClass('authorization')
				@$('.authorization-hint').text "Пароль для входа был выслан SMS-сообщением на номер +7#{phone}"
				@$('.phone-authorize-input').val(phone)
				@$('.password-authorize-input').focus()
			.catch (error) =>
				console.error error
				message = switch error.status
					when 201106 then 'Такой пользователь уже зарегистрирован.'
					else
						error.msg
				@$('.registration-hint').text message

				console.log error
			.done =>
				@setButtonLoading(@$('.button-register'), false)

		onButtonAuthorizeClick: =>
			# set button loading
			@setButtonLoading(@$('.button-authorize'), true)

			phone = @$('.phone-authorize-input').val().trim()
			password = @$('.password-authorize-input').val().trim()
			data =
				login: '7' + phone
				password: password
			Iconto.api.login(data.login, data.password)
			.then (response) =>
				console.log response
				@state.set
					isAuthorized: true
					userId: response.user_id

				@$('.bubble').removeClass('registration').removeClass('authorization')
			.catch (error) =>
				console.error error
				error.msg = switch error.status
					when 200005, 201002
						"Неверный номер телефона или пароль."
					when 202122
						"Вы превысили количество попыток авторизации, попробуйте через 30 мин."
					else
						"Произошла ошибка, попробуйте авторизоваться позже."
				@$('.authorization-hint').text error.msg
			.done =>
				@setButtonLoading(@$('.button-authorize'), false)

		onPhoneInput: (e) =>
			$registerButton = @$('.button-register')
			phone = $(e.currentTarget).val().trim().replace(/[\(,\),\-, ]+/g, '')

			# phone validation
			if phone.length is 10 and phone.match(/^\d+$/)
				$registerButton.removeAttr('disabled')
			else
				$registerButton.attr('disabled', 'disabled')

		onPhoneKeyup: (e) =>
			# Enter handling
			key = e.keyCode || e.which
			@$('.button-register').click() if key is 13

		onLoginPasswordAuthorizeKeyup: (e) =>
			# Enter handling
			key = e.keyCode || e.which
			@$('.button-authorize').click() if key is 13

		validateLoginPassword: =>
			phone = @$('.phone-authorize-input').val().trim()
			password = @$('.password-authorize-input').val().trim()
			$buttonAuth = @$('.button-authorize')

			if 6 <= password.length <= 16 and phone.match(/^\d+$/) and phone.length is 10
				$buttonAuth.removeAttr('disabled')
			else
				$buttonAuth.attr('disabled', true)

#		onCashbackModalClick: =>
#			Iconto.shared.views.modals.Alert.show
#				message: ''