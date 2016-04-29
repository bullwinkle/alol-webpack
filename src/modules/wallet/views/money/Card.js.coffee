#= require ./Cashbacks

@Iconto.module 'wallet.views.money', (Money) ->

	class Money.CardCashbackItemView extends Money.CashbackItemView
		template: JST['wallet/templates/money/card-transaction-item']

		ui:
			transactionDate: '.transaction-date'

		onRender: =>
			cashbackId = @model.get('id')
			(new Iconto.REST.Cashback(id: cashbackId)).fetch()
			.then (cashback) =>
				cashbackTime =  moment.unix(cashback.created_at).calendar()
				@ui.transactionDate.text cashbackTime
			.catch (error) ->
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onClick: =>
			route = switch @model.get('operation_type')
				when Iconto.REST.Cashback.OPERATION_TYPE_TRANSACTION
					"/wallet/money/card/#{@model.get('card_id')}/cashback/#{@model.get('id')}/transaction"
				when Iconto.REST.Cashback.OPERATION_TYPE_CASHBACK_WITHDRAW
					"/wallet/money/card/#{@model.get('card_id')}/cashback/#{@model.get('id')}/order"
			Iconto.wallet.router.navigate route, trigger: true

	class Money.CardView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
		className: 'card-view mobile-layout'
		template: JST['wallet/templates/money/card']
		childViewContainer: '.list'
		childView: Money.CardCashbackItemView

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
			InfiniteScroll:
				scrollable: '.view-content'

		ui:
			topbarRightButton: '.topbar-region .right-small'
			settingsButton: '.bank-card-info .ic-settings'

			verifyButton: '[name=verify-button]'
			rechargeButton: '.recharge-button'
			transferButton: '.transfer-button'

		events:
			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'
			'click @ui.settingsButton': 'onTopbarRightButtonClick'

			'click @ui.verifyButton': 'onVerifyButtonClick'

		bindingSources: =>
			bank: @bank
			paymentSystem: @paymentSystem

		initialize: =>
			@model = new Iconto.REST.Card(id: @options.cardId)
			@collection = new Iconto.REST.CashbackCollection()
			@bank = new Iconto.REST.Bank()
			@paymentSystem = new Iconto.REST.PaymentSystem()

			@state = new Iconto.wallet.models.StateViewModel @options
			@state.set
				topbarTitle: 'Детальная страница карты'
				topbarRightButtonClass: 'ic-settings'
				isLoadingMore: false

				isEmpty: false
				breadcrumbs: [
					{title: 'Мои карты', href: "/wallet/cards"}
					{title: 'Детальная страница карты', href: "#"}
				]

			@infiniteScrollState.on 'change:isLoadingMore', (s, isLoadingMore) =>
				@state.set 'isLoadingMore', isLoadingMore

		getQuery: =>
			card_id: @model.get('id')

		onRender: =>
			@model.fetch()
			.then (card) =>
				bankPromise = @bank.set(id: card.bank_id).fetch()
				paymentSystemPromise = Q.fcall =>
					@paymentSystem.set(id: card.system_id).fetch() if card.system_id

				preloadPromise = @preload()
				.then =>
					@state.set 'isEmpty', @collection.length is 0

				Q.all([bankPromise, paymentSystemPromise, preloadPromise])
			.then =>
				@state.set isLoading: false
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onTopbarRightButtonClick: =>
			Iconto.wallet.router.navigate "/wallet/money/card/#{@model.get('id')}/settings", trigger: true

		onVerifyButtonClick: =>
			return false if @onVerifyButtonClickLock
			@onVerifyButtonClickLock = true
			@ui.verifyButton.addClass 'is-loading'
			data =
#				type: Iconto.REST.Order.TYPE_CARD_VERIFICATION
				source_card_id: @model.get('id')
				redirect_url: document.location.href

			if @model.get('pan_id')
				data.type = Iconto.REST.Order.TYPE_CARD_VERIFICATION
			else
				data.type = Iconto.REST.Order.TYPE_CARD_REGISTRATION

			cardVerificationOrder = new Iconto.REST.Order()
			cardVerificationOrder.save(data)
			.then (response) =>
#				Iconto.shared.helpers.navigation.tryNavigate response.form_url
				Iconto.wallet.router.navigate "/wallet/payment?order_id=#{response.order_id}", trigger: true
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
				@ui.verifyButton.removeClass 'is-loading'
			.done =>
				@onVerifyButtonClickLock = false
