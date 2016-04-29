#= require ./TransactionInfo

@Iconto.module 'wallet.views.money', (Money) ->
	class Money.CardTransactionInfoView extends Money.TransactionInfoView

		onTopbarLeftButtonClick: =>
			Iconto.wallet.router.navigate "wallet/money/card/#{@model.get('card_id')}", trigger: true