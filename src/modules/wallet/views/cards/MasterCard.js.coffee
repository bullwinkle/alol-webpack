@Iconto.module 'wallet.views.money', (Money) ->
	class Money.MasterCardView extends Marionette.ItemView
		className: 'mobile-layout mastercard-view'
		template: JST['wallet/templates/cards/mastercard']

		behaviors:
			Epoxy: {}
			Layout: {}
			Form:
				submit: '.ic.ic-submit'
				events:
					click: '.ic.ic-submit'

		ui:
			cancelButton: '[name=cancel-button]'
			registerButton: '[name=register-button]'
			offerButton: '.offer-button'

		events:
			'click @ui.cancelButton': 'onCancelButtonClick'
			'click @ui.registerButton': 'onRegisterButtonClick'
			'click @ui.offerButton': 'onOfferButtonClick'

		initialize: ->
			@model = new Iconto.REST.MasterCard()
			@collection = new Iconto.REST.MasterCardCollection()

			@state = new Iconto.wallet.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Карты'
				isLoading: false
				isRegistering: false
				companyImageUrl: ''
				companyName: ''

			@company = new Iconto.REST.Company()

		onFormSubmit: ->
			cardNumber = @model.get('card_number').trim()

			# try to find this mastercard in cardpool
			@collection.fetch(filters:
				card_number: cardNumber)
			.then (cards) =>
				# no such card
				unless cards.length
					throw new ObjectError(status: 300001)

				# pick first card
				card = cards[0]
				@model.set card

				unless card.company_id
					# no such company
					throw new ObjectError(status: 203109)

				# get company info from card info
				(new Iconto.REST.Company(id: card.company_id)).fetch()
			.then (company) =>
				@state.set
					isRegistering: true
					companyName: company.name
					companyImageUrl: company.image.url

				@company.set company

				# get company client external_id
				(new Iconto.REST.CompanyClientCollection()).fetch
					company_id: company.id
					phone: @options.user.phone
				.then (clients) =>
					@state.set external_id: clients[0].external_id
				.catch (error) ->
					console.log error

			.catch (error) =>
				console.log error
				messages =
					203109: 'Компания не найдена. Проверьте введенные данные и обратитесь в чат технической поддержки (раздел Сообщения)'
					209106: 'Карта зарегистрирована на другого пользователя. Проверьте введенные данные и обратитесь в чат технической поддержки (раздел Сообщения)'
					300001: 'Карта не найдена. Проверьте введенные данные и обратитесь в чат технической поддержки (раздел Сообщения)'
				Backbone.Validation.callbacks.invalid.call @, @, 'card_number', messages[error.status], 'name'

		onCancelButtonClick: ->
			@state.set isRegistering: false

		onRegisterButtonClick: ->
			@model.save(user_id: @options.user.id)
			.then =>
				externalId = @state.get('external_id')
				# ROWS-483:
				# set route to the clientcode page if an issuer is Ulmart
				# and company client external_id is empty
				if @company.get('alias') == 'ulmart' and !externalId
					Iconto.shared.router.navigate 'wallet/profile/clientcode', trigger: true
				else
					Iconto.shared.router.navigate 'wallet/cards', trigger: true
			.catch (error) ->
				console.log error

				Iconto.shared.views.modals.ErrorAlert.show
					title: 'Ошибка'
					message: 'Произошла ошибка. Попробуйте еще раз позже'

		onOfferButtonClick: ->
			company = @company.toJSON()

			rulesText = company.rules_text?.trim()
			rulesUrl = (if company.rules_url then Iconto.shared.helpers.navigation.parseUri(company.rules_url).href else '').trim()
			hasCompanyRules = !!rulesText or !!rulesUrl

			return false unless hasCompanyRules

			if rulesUrl
				Iconto.shared.helpers.navigation.tryNavigate rulesUrl
			else if rulesText
				Iconto.shared.views.modals.LightBox.show
					html: JST['wallet/templates/cards/company-rules']
						heading: "Правила компании #{company.name}"
						content: rulesText