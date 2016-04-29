@Iconto.module 'office.views.offers', (Offers) ->

	inherit = Iconto.shared.helpers.inherit

	class Offers.CashbackItemView extends Marionette.ItemView
		className: 'cashback-item-view'
		template: JST['office/templates/offers/cashback/cashback-item']

		events:
			'click button': 'onClick'

		onClick: =>
			@trigger 'click', @model

		templateHelpers: =>
			addressCount: @options.addressCount #passed in childViewOptions
			cid: @cid
			countConditions: =>
				count = 0
				conditions = ['weekdays','price','period_from','period_to','worktime_from','worktime_to','birthday_after','birthday_before','birthday_ages','sex','first_buy','payment_count','payment_sum']
				model = @model.toJSON()
				#start counting
				for condition in conditions
					if model[condition] then count++
				return count

	class Offers.CashbacksView extends Offers.BaseOffersView
		template: JST['office/templates/offers/cashback/cashbacks']
		className: 'cashbacks-view mobile-layout'
		childView: Offers.CashbackItemView

		ui: inherit Offers.BaseOffersView::ui, {}

		events: inherit Offers.BaseOffersView::events,
			'click @ui.tabPromotion': 'onTabPromotionClick'

		initialize: =>
			@entityName = 'cashback'

			super()

			@state.set
				isCashbackTab: true

			@collection = new Iconto.REST.CashbackTemplateCollection()

