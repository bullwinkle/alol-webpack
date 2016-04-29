@Iconto.module 'wallet.views.money', (Money) ->
	class Money.TransactionInfoView extends Marionette.ItemView
		className: 'transaction-info-view mobile-layout'
		template: JST['wallet/templates/money/transaction-info']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		bindingSources: =>
			card: @card
			bank: @bank
			transaction: @transaction
			cashbackTemplate: @cashbackTemplate
			company: @company
			address: @address
			paymentSystem: @paymentSystem

		initialize: =>
			@model = new Iconto.REST.Cashback(id: @options.cashbackId)
			@transaction = new Iconto.REST.TransactionUser()
			@bank = new Iconto.REST.Bank()
			@card = new Iconto.REST.Card()
			@company = new Iconto.REST.Company()
			@address = new Iconto.REST.Address()
			@cashbackTemplate = new Iconto.REST.CashbackTemplate()
			@paymentSystem = new Iconto.REST.PaymentSystem()

			breadcrumbs =
				do =>
					if @options.cardId
						[
							{title: 'Мои карты', href: "/wallet/cards"}
							{title: 'Детальная страница карты', href: "/wallet/money/card/#{@options.cardId}"}
							{title: 'Детальная страница транзакции', href: "#"}
						]
					else
						[
							{title: 'История', href: "/wallet/money/cashback"}
							{title: 'Детальная страница транзакции', href: "#"}
						]

			@state = new Iconto.wallet.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Выписка начисления CashBack'
				breadcrumbs: breadcrumbs
				logo_url: ''
				datetime: ''

		onRender: =>
			@model.fetch()
			.then (cashback) =>
				@state.set logo_url: Iconto.shared.helpers.image.resize(cashback.image.url,
						Iconto.shared.helpers.image.FORMAT_SQUARE_SMALL)

				@transaction.set('id', cashback.operation_id).fetch()
				.then (transaction) =>
					companyPromise = Q.fcall =>
						@company.set(id: transaction.company_id).fetch() if transaction.company_id

					addressPromise = Q.fcall =>
						@address.set(id: transaction.address_id).fetch() if transaction.address_id

					cardPromise = @card.set(id: transaction.card_id).fetch()
					.then (card) =>
						bankPromise = @bank.set(id: card.bank_id).fetch()

						paymentSystemPromise = Q.fcall =>
							@paymentSystem.set(id: card.system_id).fetch() if card.system_id

						Q.all([bankPromise, paymentSystemPromise])

					promises = [cardPromise, companyPromise, addressPromise]

					if transaction.cashback_template_id
						promises.push (@cashbackTemplate.set(id: transaction.cashback_template_id)).fetch(filters: ['deleted'])


					transactionDateTime = moment.unix(transaction.payment_time).format('DD MMM. YYYY, HH:mm')
					@state.set datetime: transactionDateTime

					Q.all promises
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set
					isLoading: false