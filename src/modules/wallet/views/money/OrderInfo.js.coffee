@Iconto.module 'wallet.views.money', (Money) ->
	class Money.OrderInfoView extends Marionette.ItemView
		className: 'order-info-view mobile-layout'
		template: JST['wallet/templates/money/order-info']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		bindingSources: =>
			card: @card
			bank: @bank
			order: @order

		initialize: =>
			@model = new Iconto.REST.Cashback(id: @options.cashbackId)
			@order = new Iconto.REST.Order()
			@bank = new Iconto.REST.Bank()
			@card = new Iconto.REST.Card()

			@state = new Iconto.wallet.models.StateViewModel @options
			@state.set
				topbarTitle: 'Выписка перевода CashBack'
				breadcrumbs: [
					{title: 'История', href: "/wallet/money/cashback"}
					{title: 'Выписка перевода CashBack', href: "#"}
				]

				logo_url: ''
				datetime: ''
				showFeePercent: false

		onRender: =>
			@model.fetch()
			.then (cashback) =>
				@model.set fee_percent: @model.get('fee_percent') * 100

				@state.set
					datetime: moment.unix(cashback.created_at).format('DD MMM. YYYY, HH:mm')
					showFeePercent: (cashback.fee_percent * cashback.total) >= cashback.fee_amount

				cardPromise = @card.set('id', cashback.card_id).fetch()
				.then (card) =>
					@bank.set('id', card.bank_id).fetch()
#				@order.set('id', cashback.operation_id).fetch()

#				@transaction.set('id', cashback.operation_id).fetch()
#				.then (transaction) =>
#
#					companyPromise = Q.fcall =>
#						@company.set(id: transaction.company_id).fetch() if transaction.company_id
#
#					addressPromise = Q.fcall =>
#						@address.set(id: transaction.address_id).fetch() if transaction.address_id
#
#					cardPromise = @card.set(id: transaction.card_id).fetch()
#					.then (card) =>
#						@bank.set(id: card.bank_id).fetch()
#
#					cashbackTemplatePromise = (@cashbackTemplate.set(id: transaction.cashback_template_id)).fetch()
#
#					Q.all([cardPromise, cashbackTemplatePromise, companyPromise, addressPromise])
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set
					isLoading: false