@Iconto.module 'auth.views', (Auth) ->
	class AuthModel extends Backbone.Model
		defaults:
			login: ''
			password: ''
			is_offer_accepted: true

		validation:
			login:
				required: true
				rangeLength: [1, 20]
				pattern: 'digits'
			password:
				required: true
				rangeLength: [1, 200]
				pattern: /^[a-zA-Z0-9!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]*$/

			is_offer_accepted:
				acceptance: true


	class Auth.AuthView extends Marionette.ItemView

		template: JST['auth/templates/auth']
		className: 'auth-view'

		behaviors:
			Epoxy: {}
			Form:
				submit: '[name=submit]'
				events:
					click: '[name=submit]'
		ui:
			mainLogo: '.iconto-main-logo img'
			loginInput: '[name=login]'
			passwordInput: '[name=password]'
			submitButton: '.submit-button'
			errorBlock: '.auth-errors'
			copyrightsYear: '.copyrights .year'
			signInForm: '#signin_form'

		events:
			'submit': 'onSubmitButtonClick'

		validated: =>
			model: @model

		initialize: =>
			@model = new AuthModel @options
			@state = new Backbone.Model
				action: @options.page
				isLoading: false
				login: ''

			@listenTo @model, 'change', =>
				@ui.errorBlock.text ''

		onRender: =>
			@ui.copyrightsYear.text moment().year()
			savedUserPhone = if window.localStorage then localStorage.getItem('userPhone')
			if @model.get('page') isnt 'register' and savedUserPhone
				@model.set('login', savedUserPhone)
				_.defer =>
					localStorage.removeItem('userPhone')

		onSubmitButtonClick: (e) =>
			return false if @state.get 'isLoading'
			_.result @ui,'passwordInput.change'
			_.result @ui,'loginInput.change'

			switch @state.get('action')
				when 'signin'
					return @authorizeUser()
				when 'signup'
					return @registerUser()
				when 'restore'
					return @restorePassword()

			false

		registerUser: =>
			return unless @model.isValid ['login', 'is_offer_accepted']

			showAlert = false

			@state.set isLoading: true

			(new Iconto.REST.Offer()).fetch(type: Iconto.REST.Offer.TYPE_USER, filters: ['last'])
			.then (offer) =>
				fields =
					offer_version: offer.id
					is_offer_accepted: true
					login: @model.get('login')
				(new Iconto.REST.User()).save(fields)
			.then (user) =>
				delete Iconto.api.userId
				delete Iconto.REST.cache.user
#				Iconto.shared.views.modals.Confirm.show
#					title: "Успешная регистрация"
#					message: "Пароль для входа отправлен на номер +#{@model.get('login')}"
#					submitButtonText: 'Скачать приложение'
#					cancelButtonText: 'Перейти на сайт'
#					onCancel: =>
#						console.log 'cancel'
#						if window.localStorage
#							window.localStorage.setItem('userPhone', @model.get('login'))
#						Iconto.auth.router.navigate '/auth/signin', trigger: true
#					onSubmit: =>
#						console.log 'submit'
#						window.location.assign "#{window.location.origin}/mobile-install"

				Iconto.shared.views.modals.Alert.show
					title: "Успешная регистрация"
					message: "Пароль для входа отправлен на номер +#{@model.get('login')}"
					submitButtonText: 'Перейти на сайт'
					onCancel: =>
						console.log 'onCancel'
						if window.localStorage
							localStorage.setItem('userPhone', @model.get('login'))
						Iconto.auth.router.navigate '/auth/signin', trigger: true


			.catch (error) =>
				if error.statusText is 'error'
					error.msg = 'Произошла ошибка, попробуйте зарегистрироваться позже.'
				else
					error.msg = switch error.status
						when 208111
							"Введенный вами номер телефона некорректен."
						when 201002
							'Неправильный пароль, попробуйте еще раз.'
						when 201106
							'Пользователь с таким номером телефона уже зарегистрирован.'
						else
							'Произошла ошибка, попробуйте зарегистрироваться позже.'
				if showAlert
					Iconto.shared.views.modals.Alert.show
						title: 'Произошла ошибка'
						message: error.msg
				else
					@ui.errorBlock.text error.msg

			.done =>
				@state.set isLoading: false

		authorizeUser: =>
			return unless @model.isValid ['login', 'password']

			showAlert = false

			@state.set isLoading: true

			model = @model.toJSON()

			userPromise = Iconto.api.login(model.login, model.password)
			offerPromise = (new Iconto.REST.Offer()).fetch(type: Iconto.REST.Offer.TYPE_USER, filters: ['last'])

			Q.all([userPromise, offerPromise])
			.then ([user, offer]) =>
				console.log 'authorizeUser then', user
				throw new Error(user) unless user.user_id
				if (user.id) then Iconto.api.userId = user.id
				# accept offer
				(new Iconto.REST.User user).save
					offer_version: offer.id
					is_offer_accepted: true
			.then (user) =>
				@ui.signInForm[0].submit()
				Iconto.auth.router.complete()
			.catch (error) =>
				console.log 'authorizeUser catch', error
				defaultMessage = 'Произошла ошибка, попробуйте авторизоваться позже'
				if error.statusText is 'error'
					error.msg = defaultMessage
				else
					error.msg = switch error.status
						when 200005, 202123, 208121, 201111, 208120
							attemptsLeft = error.attempts_left
							if ( _.isUndefined(attemptsLeft) or _.isNaN(+attemptsLeft))
								"Неверный номер телефона или пароль."
							else
								switch attemptsLeft
									when 1
										"Похоже, вы забыли пароль, попробуйте его восстановить. У вас осталась одна попытка. При превышении доступ к сервису будет заблокирован на 30 мин."
									when 0
										showAlert = true
										"Вы превысили количество попыток входа. Попробуйте повторить через 30 минут."
									else
										atemptsString = "#{ attemptsLeft } #{ Iconto.shared.helpers.declension(attemptsLeft,
											['попытка', 'попытки', 'попыток']) }"
										"Неверный номер телефона или пароль. У вас осталось #{atemptsString}, при превышении доступ к сервису будет заблокирован на 30 мин."
						when 202122
							showAlert = true
							minutes = Math.floor(error.time_left / 60)
							if minutes > 1
								minutesString = "#{minutes} #{ Iconto.shared.helpers.declension(minutes,
									['минуту', 'минуты', 'минут']) }"
								"Доступ к сервису будет возможен через #{minutesString}."
							else
								"Доступ к сервису будет возможен меньше, чем через 1 минуту."
						else
							defaultMessage

				if showAlert
					@ui.errorBlock.text ''
					Iconto.shared.views.modals.Alert.show
						title: 'Произошла ошибка'
						message: error.msg
				else
					@ui.errorBlock.text error.msg

			.done =>
				@state.set isLoading: false

		restorePassword: =>
			return unless @model.isValid 'login'

			showAlert = false

			@state.set isLoading: true

			Iconto.api.post 'temp-password',
				login: @model.get('login')
			.then (response) =>
				message = "Новый пароль отправлен на номер +#{@model.get('login')}. "
				unless ( _.isUndefined(response.data.attempts_left) or _.isNaN(+response.data.attempts_left) or !_.isNumber(+response.data.attempts_left) )
					attemptsLeft = response.data.attempts_left
					atemptsString = "#{ attemptsLeft } #{ Iconto.shared.helpers.declension(attemptsLeft,
						['попытка', 'попытки', 'попыток']) }"
					switch attemptsLeft
						when 1
							message += "У вас осталась 1 попытка восстановить пароль, при превышении доступ к сервису будет заблокирован на 30 мин."
						when 0
							message = "Вы превысили количество попыток восстановления пароля. Попробуйте повторить через 30 минут."
						else
							message += "У вас осталось #{atemptsString} восстановить пароль, при превышении доступ к сервису будет заблокирован на 30 мин."

				showAlert = true

				if showAlert
					@ui.errorBlock.text ''
					Iconto.shared.views.modals.Alert.show
						title: "Восстановление пароля"
						message: message
						onCancel: =>
							if window.localStorage
								window.localStorage.setItem('userPhone', @model.get('login'))
							Iconto.auth.router.navigate '/auth/signin', trigger: true
				else
					@ui.errorBlock.text message

			.catch (error) =>
				console.error error
				defaultMessage = 'Произошла ошибка, попробуйте восстановить пароль позже.'
				if error.statusText is 'error'
					error.msg = defaultMessage
				else
					error.msg = switch error.status
						when 201108, 208120
							'Пользователь с таким номером телефона не зарегистрирован.'
						when 200009
							'Произошла ошибка, попробуйте восстановить пароль позже.'
						when 202121 # Вы превысили количество попыток восстановления пароля. Доступ к сервису будет возможен через #{minutes} мин.
							showAlert = true
							error.msg
						else
							defaultMessage

				if showAlert
					@ui.errorBlock.text ''
					Iconto.shared.views.modals.Alert.show
						title: 'Произошла ошибка'
						message: error.msg
				else
					@ui.errorBlock.text error.msg

			.done =>
				@state.set isLoading: false