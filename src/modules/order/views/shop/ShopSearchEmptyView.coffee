@Iconto.module 'order.views', (Views) ->

	class Views.ShopSearchEmptyView extends Marionette.ItemView
		template: JST['order/templates/shop/empty-search']
		tagName: 'li'
		className: 'goods-category-empty-view l-p-10 t-centered'