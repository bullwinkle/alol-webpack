@Iconto.module 'wallet.views.money', (Money) ->
	class Money.MasterCardGetView extends Marionette.ItemView
		className: 'mobile-layout mastercard-get-view'
		template: JST['wallet/templates/cards/mastercard-get']

		behaviors:
			Epoxy: {}
			Layout: {}

		ui:
			topbarLeftButton: '.topbar-region .left-small'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'

		initialize: ->
			@model = new Backbone.Model(@options.user)

			@state = new Iconto.wallet.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Где получить МАСТЕР-КАРТУ'
				topbarLeftButtonClass: ''
				topbarLeftButtonSpanClass: 'ic-chevron-left'
				isLoading: false

		onTopbarLeftButtonClick: ->
			Iconto.shared.router.navigate 'wallet/cards/mastercard', trigger: true