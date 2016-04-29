Iconto.module 'order.views', (Order) ->

	class Order.DefaultOrder extends Marionette.ItemView
		template: JST['shared/templates/orders/order-default']
		className: 'order-default'
		initialize: ->