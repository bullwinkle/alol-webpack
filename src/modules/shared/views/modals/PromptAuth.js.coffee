#= require ./BaseModal

###
	preset						- (String) name of options preset
	title 						- (String) main modal title
	message 					- (String) main modal message
	cancelButtonText 			- (String) main modal cancelButton text
	submitButtonText 			- (String) main modal submitButton text

	confirmTitle 				- (String) confirm modal title
	confirmMessage 				- (String) confirm modal message
	confirmSubmitButtonText 	- (String) confirm modal cancelButton text
	confirmCancelButtonText 	- (String) confirm modal submitButton text

	checkPreviousAuthorisedUser - (Boolean) if true, then if another user authorised - he will be redirected to '/', else will be stay on current page
	confirmOnClose				- (Boolean) show another cofirm modal on cancel or not
	login 						- (String) user login
	password 					- (String) user password

	successCallback				- (Function) will be executed if authorisation was not success
	errorCallback				- (Function) will be executed if authorisation was totally canceled
###


presets =
	soft:
		title: "Пожалуйста, авторизуйтесь"
		message: "Данное действие доступно только авторизованным пользователям"
		cancelButtonText: "Отмена"
		submitButtonText: "Отправить"
		confirmTitle: "Авторизация"
		confirmMessage: "Вы будете перенаправлены на страницу регистрации"
		confirmSubmitButtonText: "Перейти"
		confirmCancelButtonText: "Вернуться"
		checkPreviousAuthorisedUser: false
		confirmOnClose: false
		showRegistrationLink: true
		successCallback: ->
		errorCallback: ->

	unauthorized:
		title: "Пожалуйста, авторизуйтесь"
		message: "Данное действие доступно только авторизованным пользователям"
		cancelButtonText: "Отмена"
		submitButtonText: "Отправить"
		confirmTitle: "Авторизация"
		confirmMessage: "Вы будете перенаправлены на страницу регистрации"
		confirmSubmitButtonText: "Перейти"
		confirmCancelButtonText: "Вернуться"
		checkPreviousAuthorisedUser: true
		confirmOnClose: true
		showRegistrationLink: true
		successCallback: =>
			Backbone.history.loadUrl(Backbone.history.fragment)

		errorCallback: =>

	sessionExpired:
		title: "Время сессии истекло"
		message: "В целях безопасности просим вас заново ввести ваш логин и пароль"
		cancelButtonText: "Отмена"
		submitButtonText: "Отправить"
		confirmTitle: "Время сессии истекло"
		confirmMessage: "Вы уверены, что хотите выйти?"
		confirmSubmitButtonText: "Выйти из АЛОЛЬ"
		confirmCancelButtonText: "Вернуться к форме входа"
		confirmOnClose: true
		checkPreviousAuthorisedUser: true
		showRegistrationLink: true
		successCallback: =>
			Backbone.history.loadUrl(Backbone.history.fragment)

		errorCallback: =>


@Iconto.module 'shared.views.modals', (Modals) ->
	inherit = Iconto.shared.helpers.inherit

	class PromptAuthModel extends Modals.BaseModel
		defaults: ->
			title: "Время сессии истекло"
			message: "В целях безопасности, просим вас заново ввести ваш логин и пароль."
			cancelButtonText: "Отмена"
			submitButtonText: "Отправить"

			confirmTitle: "Время сессии истекло"
			confirmMessage: "Вы уверены, что хотите выйти?"
			confirmSubmitButtonText: "Выйти из АЛОЛЬ"
			confirmCancelButtonText: "Вернуться к форме входа"

			confirmOnClose: true
			checkPreviousAuthorisedUser: true
			showRegistrationLink: false

			preventNavigate: false # prevent navigate to '/' after success login if new user (not previous) logged in

			login: ""
			password: ""

			successCallback: =>
				console.info('logged in')

			errorCallback: =>
				Iconto.api.logout()
				.then =>
					Iconto.shared.router.action 'auth'

	class Modals.PromptAuth extends Modals.BaseModal
		@PRESETS = _.keys presets

		className: 'prompt prompt-auth'

		template: JST['shared/templates/modals/prompt-auth']

		ui =
			form:
				selector: 'form[name=signin]'
				events:
					'submit': 'onFormSubmit'
			loginInput:
				selector: '[name=login]'
				events:
					'input.prompt paste.prompt change.prompt': 'onLoginInput'
			passwordInput:
				selector: '[name=password]'
				events:
					'input.prompt paste.prompt change.prompt': 'onInput'
			submitButton:
				selector: '.submit-button'
				events: {}
			cancelButton:
				selector: '.cancel-button'
				events: {}
			errorMessageEl:
				selector: '.error-message'
				events: {}

		cancelEl: ui.cancelButton.selector
		submitEl: ui.submitButton.selector

		initialize: (options = {}) ->
			if Modals.PromptAuth._singleton
				return Modals.PromptAuth._singleton
			else
				Modals.PromptAuth._singleton = @

			optionsPreset = options.preset
			if optionsPreset and presets[optionsPreset]
				delete options.preset
				options = _.extend presets[optionsPreset], options

			options.lastAuthorizedUserId = Iconto.api.lastAuthorizedUserId

			@model = new PromptAuthModel(options)

			@listenTo Backbone.history, 'route', @destroy

		onRender: =>
			@ui = {}
			for element of ui
				el = ui[element]
				$el = @$(el.selector)
				unless $el.length > 0 then console.warn "ui el did not find: #{el.selector}"

				for event of el.events
					callback = @[el.events[event]]
					unless callback then console.warn "callback for event #{event} did not find: #{el.events[event]}"
					$el.on(event, callback)

				@ui[element] = $el

			@ui.loginInput.trigger 'change'
			@ui.passwordInput.trigger 'change'

		onInput: (e) =>
			@ui.errorMessageEl.text ''
			$input = $(e.currentTarget)
			value = $input.val()
			name = $input.attr 'name'
			@model.set name, value, validate: true
			true

		onLoginInput: (e) =>
			@ui.errorMessageEl.text ''
			$input = $(e.currentTarget)
			value = Iconto.shared.behaviors.CustomBindingFilters.phone.set($input.val())
			name = $input.attr 'name'
			@model.set name, value, validate: true
			true

		beforeCancel: =>
			unless @model.get('confirmOnClose') then return true
			return false if @confirmExitShown
			result = false

			confirm = new Promise (resolve, reject) =>
				Iconto.shared.views.modals.Confirm.show
					title: @model.get 'confirmTitle'
					message: @model.get 'confirmMessage'
					submitButtonText: @model.get 'confirmSubmitButtonText'
					cancelButtonText: @model.get 'confirmCancelButtonText'
					onSubmit: ->
						resolve('submited')
					onCancel: ->
						reject('canceled')

			@confirmExitShown = true
			confirm.then =>
				@destroy()
				errorCallback = @model.get('errorCallback')
				if errorCallback then errorCallback()
				console.log 'then', errorCallback
			.catch (err) =>
				@confirmExitShown = false
				console.log 'catch'
			.done =>
				console.log 'DONE'
			false

		beforeSubmit: =>
			@ui.form.submit() # jQuer submit
			false

		onFormSubmit: =>
			model = @model.toJSON()

			@ui.submitButton.addClass 'is-loading'

			Iconto.api.login(model.login, model.password)
			.then =>
				Iconto.api.auth()
			.then (user) =>
				@ui.form[0].submit() # login and password are correct - do native submit form to get native browser saving password prompt
				@destroyWithNavigate = @model.get('checkPreviousAuthorisedUser') && @model.get('lastAuthorizedUserId') isnt user.user_id
				if @destroyWithNavigate and !@model.get('preventNavigate')
					Iconto.shared.router.navigate '/', trigger: true
				else
					#					if @model.get('from') is 'AuthenticatedRouter'
					successCallback = @model.get('successCallback')
					if successCallback then successCallback()
			.then =>
				@destroy()
			.catch (error) =>
				console.error error
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
										"Вы превысили количество попыток входа. Попробуйте повторить через 30 минут."
									else
										atemptsString = "#{ attemptsLeft } #{ Iconto.shared.helpers.declension(attemptsLeft,
											['попытка', 'попытки', 'попыток']) }"
										"Неверный номер телефона или пароль. У вас осталось #{atemptsString}, при превышении доступ к сервису будет заблокирован на 30 мин."
						when 202122
							minutes = Math.floor(error.time_left / 60)
							if minutes > 1
								minutesString = "#{minutes} #{ Iconto.shared.helpers.declension(minutes,
									['минуту', 'минуты', 'минут']) }"
								"Доступ к сервису будет возможен через #{minutesString}."
							else
								"Доступ к сервису будет возможен меньше, чем через 1 минуту."

						else
							defaultMessage

				@ui.errorMessageEl.text error.msg
				errorCallback = @model.get('errorCallback')
				if errorCallback then errorCallback error

			.done =>
				@ui.submitButton.removeClass 'is-loading'

			false # do not native submit form, untill login and password are correct

		clickOutside: (e) =>
			if @model.get('confirmOnClose')

				if e.target is @el
					@pulse()
				return false

			else super

		pulse: =>
			$modal = @$('.bbm-modal--open')
			transitionEvent = Iconto.shared.helpers.transitionEndEventName
			$modal.on transitionEvent, =>
				$modal.removeClass 'pulse'
				$modal.off transitionEvent
			$modal.addClass 'pulse'

		destroy: =>
			super
			delete Modals.PromptAuth._singleton
			@ui.loginInput.off 'input.prompt paste.prompt change.prompt'
			@ui.passwordInput.off 'input.prompt paste.prompt change.prompt'
			@ui.form.off 'submit'

		@close: =>
			if Modals.PromptAuth._singleton
				Modals.PromptAuth._singleton.destroy()

		@show: (options) =>
			if Modals.PromptAuth._singleton
				Modals.PromptAuth._singleton.pulse()
				return Modals.PromptAuth._singleton

			prompt = new Modals.PromptAuth options
			prompt.show()
			prompt