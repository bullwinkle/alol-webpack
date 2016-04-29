@Iconto.module 'root.views.branding', (Branding) ->
	class LoginModel extends Backbone.Model
		defaults:
			login: ''
			password: ''
		validation:
			login:
				required: true
				pattern: 'phone'
			password:
				required: true
				rangeLength: [6, 16]

	_.extend LoginModel::, Backbone.Validation.mixin

	class Branding.Layout extends Marionette.LayoutView
		className: 'branding-view'
		template: JST['root/templates/branding/layout']

		ui:
			companyLogo: '.company-logo'
			password: 'input[name=password]'
			loginError: '.login-error'
			button: 'button'
			modeButton: '.mode'
			restoreButton: '.restore-button'
			welcomeText: '.welcome-text'
			submitButton: '.submit-button'

		events:
			'click @ui.modeButton': 'onModeClick'
			'click @ui.restoreButton': 'onRestoreButtonClick'
			'submit form': 'onFormSubmit'

		modelEvents: {}

		behaviors:
			Epoxy: {}
			Form:
				events:
					submit: 'form'

		validated: ->
			model: @model

		initialize: (@options) =>
			$icontoBlue3 = '#3eaddb'

			window.ICONTO_APPLICATION_DOMAIN_SETTINGS.background_color ||= $icontoBlue3

			@model = new LoginModel()
			@company = new Iconto.REST.Company(id: window.ICONTO_APPLICATION_DOMAIN_SETTINGS.company_id)
			@companySettings = new Iconto.REST.CompanySettings(window.ICONTO_APPLICATION_DOMAIN_SETTINGS)

			@state = new Backbone.Epoxy.Model
				registration: false
				phone: ''
				mode: 'register' #login, register, restore

			@state.addComputed 'buttonText',
				deps: ['mode']
				get: (mode) ->
					switch (mode)
						when 'login' then 'Войти'
						when 'register' then 'Зарегистрироваться'
						when 'restore' then 'Восстановить'

			@state.addComputed 'modeText',
				deps: ['mode']
				get: (mode) ->
					switch (mode)
						when 'login' then 'Регистрация'
						when 'register', 'restore' then 'Вход'

			@state.addComputed 'showPasswordInput',
				deps: ['mode']
				get: (mode) ->
					mode is 'login'

		onRender: =>
			@company.fetch()
			.then (company) =>
				updatedAt = @companySettings.get('updated_at')
				url = company.image.url
				url += "?#{updatedAt}" if updatedAt
				@ui.companyLogo.attr 'src', url + '&resize=w[200]h[200]'
			.catch (error) =>
				console.error error
			.done()

			@ui.welcomeText.html @linkify window.ICONTO_APPLICATION_DOMAIN_SETTINGS.welcome_text

		linkify: (text) =>
			if text
				text = text.replace /((https?\:\/\/)|(www\.))(\S+)(\w{2,4})(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/gi, (url) ->
					full_url = url
					full_url = 'http://' + full_url unless full_url.match('^https?:\/\/')
					a = document.createElement('a')
					a.href = url
					'<a href="' + full_url + '" data-bypass target="_blank">' + a.host + '</a>';
			text

		onFormSubmit: (e) =>
			# check validity and lock (is-loading)
#			return false if @ui.button.hasClass('is-loading') or not @model.isValid(true)
			return false if @ui.button.hasClass('is-loading')

			switch (@state.get('mode'))
				when 'login'
					@login()
				when 'register'
					@register()
				when 'restore'
					@restore()

			return false

		onModeClick: =>
			mode = @state.get('mode')
			@state.set mode: if mode is 'login' then 'register' else 'login'
			@ui.loginError.text('').addClass('hide')
			@model.validation.password.required = @state.get('mode') is 'login'
			@model.set password: '' if @state.get('mode') is 'register'

		onRestoreButtonClick: =>
			@state.set mode: 'restore'
			@ui.loginError.text('').addClass('hide')
			@model.validation.password.required = false
			@model.set password: ''

		login: =>
			return unless @model.isValid ['login', 'password']
			# lock button
			@ui.button.addClass('is-loading')
			model = @model.toJSON()
			Iconto.api.login(model.login, model.password, @company.get('id'))
			.then =>
				route = "wallet/company/#{@company.get('id')}"
				Iconto.root.router.navigate route, trigger: true, replace: true
			.catch (error) =>
				console.log error
				defaultMessage = 'Произошла ошибка, попробуйте авторизоваться позже'
				if error.statusText is 'error'
					error.msg = defaultMessage
				else
					error.msg = switch error.status
						when 200005, 202123, 208121, 201111, 208120
							if ( _.isUndefined(error.attempts_left) or _.isNaN(+error.attempts_left) or !_.isNumber(+error.attempts_left) )
								"Неверный номер телефона или пароль."
							else
								attemptsLeft = error.attempts_left
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

				@ui.loginError.text(error.msg).removeClass('hide')
				@ui.button.removeClass('is-loading')
			.done()

		register: =>
			return unless @model.isValid ['login']
			# lock button
			@ui.button.addClass('is-loading')
			model = @model.toJSON()
			(new Iconto.REST.Offer()).fetch(type: Iconto.REST.Offer.TYPE_USER, filters: ['last'])
			.then (offer) =>
				fields =
					offer_version: offer.id
					is_offer_accepted: true
					login: model.login
					company_id: @company.get('id')
				(new Iconto.REST.User()).save(fields)
			.then =>
				@ui.button.removeClass('is-loading')
				Iconto.shared.views.modals.Alert.show
					title: "Успешная регистрация"
					message: "Пароль для входа был выслан SMS-сообщением на номер +#{model.login}."
				@state.set mode: 'login'
			.catch (error) =>
				console.error error
				if error.statusText is 'error'
					error.msg = 'Произошла ошибка, попробуйте зарегистрироваться позже.'
				else
					switch error.status
						when 208111
							error.msg = "Введенный Вами номер телефона некорректен."
						when 201002
							error.msg = 'Неправильный пароль, попробуйте еще раз.'
						when 201106
							error.msg = null
							Iconto.shared.views.modals.Alert.show
								message: 'Однажды вы уже получили учетную запись АЛОЛЬ. Используйте ее для входа. Если забыли пароль - восстановите его.'
								onCancel: =>
									@state.set 'mode', 'login'
						else
							error.msg = 'Произошла ошибка, попробуйте зарегистрироваться позже.'

				if error.msg then @ui.loginError.text(error.msg).removeClass('hide')
				@ui.button.removeClass('is-loading')
			.done()

		restore: =>
			return unless @model.isValid 'login'
			# lock button
			@ui.button.addClass('is-loading')
			model = @model.toJSON()
			Iconto.api.post('temp-password', login: model.login)
			.then (response) =>
				@ui.button.removeClass('is-loading')
				Iconto.shared.views.modals.Alert.show message: 'Новый пароль отправлен на указанный номер телефона.'
				@state.set mode: 'login'
			.catch (error) =>
				console.error error
				if error.statusText is 'error'
					error.msg = 'Произошла ошибка, попробуйте восстановить пароль позже.'
				else
					error.msg = switch error.status
						when 201108, 208120
							'Пользователь с таким номером телефона не зарегистрирован.'
						when 200009
							'Произошла ошибка, попробуйте восстановить пароль позже.'
						else
							'Произошла ошибка, попробуйте восстановить пароль позже.'
				@ui.loginError.text(error.msg).removeClass('hide')
				@ui.button.removeClass('is-loading')
			.done()