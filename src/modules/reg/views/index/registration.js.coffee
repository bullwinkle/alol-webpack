@Iconto.module 'reg.views', (Views) ->

	class RegModel extends Backbone.Epoxy.Model
		defaults:
			phone: ''
			password: ''
			card_number: ''
			terms_of_use: true
			isAuthorization: true #placed here to dinamically validation

		validation: ->
			if @get 'isAuthorization'
				phone:
					required: true
					pattern: 'digits'
					rangeLength: [1, 20]
				password:
					required: true
					minLength: 3
				terms_of_use:
					required: false
			else
				phone:
					required: true
					pattern: 'digits'
					rangeLength: [1, 20]
				password:
					required: false
				terms_of_use:
					required: true
					acceptance: true

	_.extend RegModel::, Backbone.Validation.mixin

	class Views.Registration extends Marionette.ItemView

		className: 'reg-registration'
		template: JST['reg/templates/index/registration']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		ui:
			regForm: '.registration-form'

			loginInput: '.input-login'
			passwordInput: '.password-input'

			changeStatechangeRestoreButton: '.change-state-restore'
			changeStatechangeRegistationButton: '.change-state-registation'
			changeStatechangeAuthorizationButton: '.change-state-aurhorization'

			submitButton: 'button.submit-form'

			topbarLeftButton: '.topbar-region .left-small'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
			'click .chenge-state a': 'onStateChangeIsAuth'
			'click @ui.restoreButton': 'onStateChangeIsRestore'

			'click @ui.changeStatechangeRestoreButton': 'onStateChangeRestore'
			'click @ui.changeStatechangeRegistationButton': 'onStateChangeRegistation'
			'click @ui.changeStatechangeAuthorizationButton': 'onStateChangeAuthorization'

			'submit': 'onFormSubmit'

		modelEvents:
			'validated:valid': 'onModelValid'
			'validated:invalid': 'onModelInvalid'

		initialize: =>
			@model = new RegModel()
			@user = new Backbone.Model()

			@state = new Iconto.reg.models.StateViewModel @options
			@state.set
				topbarLeftButtonClass: ''
				topbarLeftButtonSpanClass: ''
				submitButtonDisabled: true
				preventSubmit: true
				terms_of_use: true
				phoneNumber: ''
				loginInput:''
				isAuthorization: true
				isRestorePassword: false

			@listenTo @state,
				'change:phoneNumber': @onStatePhoneNumberChange
				'change:isAuthorization': @onStateIsAuthorizationChange

		onRender: =>
			_.defer =>
				Iconto.api.logout()
				.then =>
					@state.set 'isLoading', false
				.done()

		authorizeUser: =>
			if @model.isValid ['phone', 'password']

				@ui.submitButton.attr('disabled', 'disabled').addClass('is-loading')
				model = @model.toJSON()
				Iconto.api.post( 'auth', login: model.phone, password: model.password)
				.then (response) =>
					(new Iconto.REST.Order(type: Iconto.REST.Order.TYPE_CARD_REGISTRATION, redirect_url: '/reg/thanks', error_redirect_url: '/reg' )).save()
					.then (order) =>
						Iconto.shared.helpers.navigation.tryNavigate( order.form_url )
				.catch (error) =>
					console.error error
					if error.statusText is 'error'
						error.msg = 'Произошла ошибка, попробуйте авторизоваться позже.'
					else
						error.msg = switch error.status
							when 200005, 201002
								"Неверный номер телефона или пароль."
							when 202122
								"Вы превысили количество попыток авторизации, попробуйте через 30 мин."
							else
								"Произошла ошибка, попробуйте авторизоваться позже."
					Iconto.shared.views.modals.Alert.show
						title: 'Произошла ошибка'
						message: error.msg
				.done =>
					@ui.submitButton.removeAttr('disabled').removeClass('is-loading')

			else
				Iconto.shared.views.modals.Alert.show
					title: 'Ошибка'
					message: 'Введенные данные не корректны.'

		registerUser: (e) =>
			if @model.isValid ['phone','terms_of_use']
				@trigger 'registration',e
				@ui.submitButton.prop('disabled', true).addClass('is-loading')

				user = new Iconto.REST.User
					login: @model.get 'phone'
				user.save()
				.then (response) =>
					title = 'Успешная регистрация'
					message = "Пароль для входа был выслан SMS-сообщением на номер +#{@model.get('phone')}."
					Iconto.shared.views.modals.Alert.show
						title: title
						message: message
						onSubmit: =>
							@ui.submitButton.prop('disabled', false)
						onCancel: =>
							@ui.submitButton.prop('disabled', false)
					@state.set
						isAuthorization: true
						isRestorePassword: false
				.catch (error) =>
					console.error error
					@ui.submitButton.removeClass('is-loading')

					title = "Произошла ошибка"
					message = switch error.status
						when 208111
							"Введенный Вами номер телефона некорректен."
						when 201002
							'Неправильный пароль, попробуйте еще раз.'
						when 201106
							'Пользователь с таким номером телефона уже зарегистрирован.'
						else
							'Произошла ошибка, попробуйте зарегистрироваться позже.'
					Iconto.shared.views.modals.Alert.show
						title: title
						message: message
						onSubmit: ->
							@cancel()
							return false
						onCancel: =>
							@ui.submitButton.prop('disabled', false)
							return false
				.done =>
					@ui.submitButton.prop('disabled', false).removeClass('is-loading')

			else
				Iconto.shared.views.modals.Alert.show
					title: 'Ошибка'
					message: 'Введенные данные не корректны.'

		restorePassword: (e) =>
			if @model.isValid 'phone'
				@trigger 'authorisation',e
				@ui.submitButton.prop('disabled', true).addClass('is-loading')

				Iconto.api.post('temp-password', login: @model.get('phone'))
				.then (response) =>

					@onStateChangeAuthorization

					Iconto.shared.views.modals.Alert.show message: 'Новый пароль отправлен на указанный номер телефона.'
					@state.set
						isAuthorization: true
						isRestorePassword: false

				.catch (error) =>
					console.error error
					if error.statusText is 'error'
						error.msg = 'Произошла ошибка, попробуйте авторизоваться позже.'
					else
						error.msg = switch error.status
							when 201108
								'Пользователь с таким номером телефона не зарегистрирован.'
							when 200009
								'Произошла ошибка, попробуйте зарегистрироваться позже.'
							else
								error.msg
					Iconto.shared.views.modals.Alert.show
						title: 'Произошла ошибка'
						message: error.msg

				.done =>
					@ui.submitButton.prop('disabled', false).removeClass('is-loading')
			else
				Iconto.shared.views.modals.Alert.show
					title: 'Ошибка'
					message: 'Введенные данные не корректны.'

		onTopbarLeftButtonClick: =>
			Iconto.reg.router.navigate "/reg", trigger: true

		onModelValid: =>
			@state.set
				preventSubmit: false

		onModelInvalid: =>
			@state.set
				preventSubmit: true

		onStatePhoneNumberChange: (state, phoneNumber) =>
			saveValue = $.trim @ui.loginInput.val().replace(/[\ (\)\-\+\_]/g, '')
			@model.set 'phone', "7#{Iconto.shared.helpers.phone.parse(saveValue)}"

		onStateIsAuthorizationChange: (state, isAuthorization) =>
			@model.set 'isAuthorization', isAuthorization

		onStateChangeRegistation: =>
			@state.set
				isAuthorization: false
				isRestorePassword: false

		onStateChangeAuthorization: =>
			@state.set
				isAuthorization: true
				isRestorePassword: false

		onStateChangeRestore: =>
			@state.set
				isAuthorization: false
				isRestorePassword: true

		onFormSubmit: (e) =>
			@model.validate()
			if App.modals.modals.length isnt 0
				e.preventDefault()
				return false
			if @state.get('isAuthorization') and not @state.get('isRestorePassword')            # Authorize
				@authorizeUser(e)
			else if not @state.get('isAuthorization') and not @state.get('isRestorePassword')   # Register
				@registerUser(e)
			else if @state.get('isRestorePassword') and not @state.get('isAuthorization')       # Restore password
				@restorePassword(e)
