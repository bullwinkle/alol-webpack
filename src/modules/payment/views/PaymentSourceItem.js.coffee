@Iconto.module 'payment.views', (Views) ->

	class Views.PaymentSource extends Backbone.Model
		@TYPE_BOUND_CARD = 1
		@TYPE_OTHER_CARD = 2

		defaults:
			type: @TYPE_BOUND_CARD

	class Views.PaymentSourceCollection extends Backbone.Collection
		model: Views.PaymentSource

	class Views.PaymentSourceItemView extends Marionette.ItemView
		tagName: 'li'
		className: 'tab'
		template: JST['payment/templates/payment-source-item']

		templateHelpers:
			TYPE_BOUND_CARD: Views.PaymentSource.TYPE_BOUND_CARD
			TYPE_OTHER_CARD: Views.PaymentSource.TYPE_OTHER_CARD

		events:
			'click': 'onClick'

		onClick: =>
			@trigger 'click', @model