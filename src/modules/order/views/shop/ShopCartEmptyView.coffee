@Iconto.module 'order.views', (Views) ->

	class Views.ShopCartEmptyView extends Marionette.ItemView
		template: JST['order/templates/shop/shop-cart-empty']
		tagName: 'li'
		className: 'goods-category-empty-view l-p-10 t-centered'
		ui:
			closeCartButton: '.close-cart'

		events:
			'click @ui.closeCartButton': 'onCloseCartButtonClick'

		onCloseCartButtonClick: (e) =>
			@trigger 'click:closeCart'