@Iconto.module 'wallet.views.registrator', (Registrator) ->
	class RegistratorModel extends Iconto.REST.RESTModel
		urlRoot: 'user-registration'
		defaults:
			login: ''
			card_number: ''
			company_id: 2775

		validation:
			login:
				required: true
				rangeLength: [1, 20]
				pattern: 'phone'

			card_number:
				required: true
				pattern: 'cardNumber'
				luhn: true

			company_id:
				required: true
				pattern: 'digits'

	class Registrator.RegistratorView extends Marionette.ItemView
		className: 'mobile-layout registrator-view'
		template: JST['wallet/templates/registrator/registrator']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		ui:
			registerButton: 'button.register'
			form: '.registrator-form'
			input: 'input'

		events:
			'submit @ui.form': 'onFormSubmit'

		initialize: ->
			@model = new RegistratorModel()

			@state = new Iconto.wallet.models.StateViewModel @options
			@state.set
				topbarTitle: 'Регистратор'
				topbarLeftButtonClass: 'menu-icon left-off-canvas-toggle hide-on-web-view'
				isLoading: false
				login: ''

			@listenTo @state, 'change:login', @onStateLoginChange

			Backbone.Validation.bind @,
				model: @model

		clearForm: =>
			@ui.form.addClass 'hide-validation-errors'
			@state.set 'login', ''
			@model.clear()

		onStateLoginChange: (state, value, options) =>
			parsedPhone = Iconto.shared.helpers.phone.parse value
			parsedPhone = parsedPhone.replace(/^\+7/, '7') if /^\+7/.test(parsedPhone)
			parsedPhone = parsedPhone.replace(/^8/, '7') if /^8/.test(parsedPhone) or /^\+8/.test(parsedPhone)
			parsedPhone = parsedPhone.replace(/^9/, '79') if /^9/.test(parsedPhone)
			parsedPhone = "7#{parsedPhone}" if parsedPhone.length is 10
			@model.set 'login', parsedPhone, validate: true


		onFormSubmit: (e) =>
			e.preventDefault()
			unless ( _.isEmpty(@model.get('login')) and _.isEmpty(@model.get('card_number')) )
				@ui.form.removeClass 'hide-validation-errors'

			if @model.isValid()
				@ui.input.blur()
				@ui.registerButton.addClass('is-loading').prop 'disabled', true

				@model.save()
				.dispatch(@)
				.then (response) =>
					message = if response.exists_user
						"Новая карта привязана к существующему пользователю."
					else
						"Новый пользователь успешно зарегистрирован."
					Iconto.shared.views.modals.Alert.show
						message: message
					@clearForm()

				.catch (error) =>
					console.error error
					error.msg = switch error.status
						when 208111 then "Введенный Вами номер телефона некорректен."
						when 201106 then "Пользователь с таким номером телефона уже зарегистрирован."
						when 307102 then "Карта с такими данными уже зарегистрирована. Пожалуйста, свяжитесь со службой поддержки АЛОЛЬ, support@alol.io."
						when 107129 then "Вы можете привязать не более 8 карт."
						when 208132,208133,208134,208135 then "Введенный Вами номер карты некорректен."
						else
							"Произошла ошибка, попробуйте позже."

					Iconto.shared.views.modals.ErrorAlert.show(error)
				.done =>
					@ui.registerButton.removeClass('is-loading').prop 'disabled', false
