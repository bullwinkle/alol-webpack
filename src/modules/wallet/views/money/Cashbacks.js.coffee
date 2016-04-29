@Iconto.module 'wallet.views.money', (Money) ->
	class Money.CashbackItemView extends Marionette.ItemView
		tagName: 'button'
		template: JST['wallet/templates/money/transaction-item']
		className: 'cashback-item-view list-item'

		ui:
			cardTitle: '.card-title'
			cardNumber: '.card-number'

		events:
			'click': 'onClick'

		onClick: =>
			route = switch @model.get('operation_type')
				when Iconto.REST.Cashback.OPERATION_TYPE_TRANSACTION
					"/wallet/money/cashback/#{@model.get('id')}/transaction"
				when Iconto.REST.Cashback.OPERATION_TYPE_CASHBACK_WITHDRAW
					"/wallet/money/cashback/#{@model.get('id')}/order"
			Iconto.wallet.router.navigate route, trigger: true

	class Money.CashbacksView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
		className: 'cashbacks-view mobile-layout money-layout'
		template: JST['wallet/templates/money/cashbacks']
		childView: Money.CashbackItemView
		childViewContainer: '.list'

		behaviors:
			Epoxy: {}
			InfiniteScroll:
				scrollable: '.list-wrap'

		collectionEvents:
			'add remove reset': 'onCollectionChange'

		initialize: =>
			@state = new Iconto.wallet.models.StateViewModel @options
			@state.set
#				topbarTitle: 'Деньги'
				balance: @options.user.balance
				isCashbacksPage: true
				isLoadingMore: false
				isLoading: false
				isEmpty: true

				tabs: [
					{title: 'Мои карты', href: '/wallet/cards'},
					{title: 'История', href: '/wallet/money/cashback', active: true}
				]

			@infiniteScrollState.on 'change:isLoadingMore', (s, isLoadingMore) =>
				@state.set 'isLoadingMore', isLoadingMore

			@collection = new Iconto.REST.CashbackCollection()

		onRender: =>
			@preload()
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onCollectionChange: =>
			@state.set 'isEmpty', @collection.length is 0

