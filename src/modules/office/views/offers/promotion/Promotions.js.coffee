@Iconto.module 'office.views.offers', (Offers) ->

	inherit = Iconto.shared.helpers.inherit

	class Offers.PromotionsItemView extends Marionette.ItemView
		className: 'promotion-item-view'
		template: JST['office/templates/offers/promotion/promotion-item']

		templateHelpers: =>
			addressCount: @options.addressCount

		events:
			'click button': 'onClick'

		onClick: =>
			@trigger 'click', @model

	class Offers.PromotionsView extends Offers.BaseOffersView
		template: JST['office/templates/offers/promotion/promotions']
		className: 'promotions-view mobile-layout'
		childView: Offers.PromotionsItemView

		ui: inherit Offers.BaseOffersView::ui, {}

		events: inherit Offers.BaseOffersView::events,
			'click @ui.tabCashback': 'onTabCashbackClick'

		initialize: =>
			@entityName = 'promotion'

			super()

			@state.set
				isCashbackTab: false

			@collection = new Iconto.REST.PromotionCollection()