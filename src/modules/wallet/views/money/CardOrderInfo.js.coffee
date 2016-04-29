#= require ./OrderInfo

@Iconto.module 'wallet.views.money', (Money) ->
	class Money.CardOrderInfoView extends Money.OrderInfoView

		onTopbarLeftButtonClick: =>
			Iconto.wallet.router.navigate "wallet/money/card/#{@model.get('card_id')}", trigger: true