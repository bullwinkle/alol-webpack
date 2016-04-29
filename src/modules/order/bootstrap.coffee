Iconto.module 'order', (Order) ->
	Order.router = new Order.OrderRouter
		controller: new Order.OrderController()