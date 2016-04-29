@Iconto.module 'oauth.views', (Oauth) ->
	class SignupModel extends Backbone.Model
		defaults:
			phone: ''
			password: ''
		validation:
			phone:
				required: true
				pattern: /^\d{10}$/
			password:
				required: true

	_.extend SignupModel::, Backbone.Validation.mixin

	class Oauth.AuthView extends Marionette.ItemView
		className: 'auth-view'
		template: JST['oauth/templates/auth']

		behaviors:
			Epoxy: {}

		ui:
			submit: '[name=submit]'
			changeModeButton: '.change-mode-button'

		events:
			'click [name=submit]': 'onSubmitClick'
			'keyup input': 'onInputKeyup'
			'click @ui.changeModeButton': 'onChangeModeButtonClick'

		modelEvents:
			'validated:valid': ->
				@ui.submit.removeAttr 'disabled'
			'validated:invalid': ->
				@ui.submit.attr 'disabled', true

		initialize: =>
			@model = new SignupModel()

			@state = new Backbone.Model
				isRegistering: false
				error: false
				success: false
				messageText: ''

			@listenTo @state, 'change:isRegistering', (model, value) =>
				@model.validation.password.required = !value
				@model.validate()
				@model.set password: '' if value

		onChangeModeButtonClick: =>
			@state.set isRegistering: !@state.get('isRegistering')

		onInputKeyup: (e) =>
			keycode = e.which || e.keyCode
			if keycode is 13 and not @ui.submit.attr('disabled')
				@onSubmitClick()

		onSubmitClick: =>
			@ui.submit.attr('disabled', 'disabled')

			model = @model.toJSON()

			if @state.get('isRegistering')
				# register new user
				(new Iconto.REST.User()).save(login: "7#{model.phone}")
				.then =>
					@state.set
						isRegistering: false
						error: false
						success: true
						messageText: "Пароль для входа был выслан SMS-сообщением на номер +7#{model.phone}."
				.catch (error) =>
					console.error error
					@ui.submit.removeAttr('disabled')

					error.msg = switch error.status
						when 201106
							'Пользователь с таким номером телефона уже зарегистрирован.'
						else
							"Произошла ошибка, попробуйте зарегистрироваться позже."

					@state.set
						error: true
						success: false
						messageText: error.msg
				.done()
			else
				# authorize user
				Iconto.api.login("7#{model.phone}", model.password)
				.then =>
#					@state.set
#						error: false
#						messageText: ''

					@trigger 'user:authorized'
				.catch (error) =>
					console.error error
					@ui.submit.removeAttr('disabled')

					error.msg = switch(error.status)
						when 200005, 201002
							"Неверный номер телефона или пароль."
						when 202122
							"Вы превысили количество попыток авторизации, попробуйте через 30 мин."
						else
							"Произошла ошибка, попробуйте авторизоваться позже."

					@state.set
						error: true
						success: false
						messageText: error.msg
				.done()