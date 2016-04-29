@Iconto.module 'order.views', (Views) ->

	class Views.ShopCategoryEmptyView extends Marionette.ItemView
		template: JST['order/templates/shop/empty-catalog']
		tagName: 'li'
		className: 'goods-category-empty-view l-p-10 t-centered'