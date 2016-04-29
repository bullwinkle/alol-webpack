Iconto.module 'shared.views.orders', (Orders) ->

	class Orders.DefaultOrder extends Marionette.ItemView
		template: JST['shared/templates/orders/order-default']
		className: 'order-default'
		initialize: ->
			console.log 'order-default'