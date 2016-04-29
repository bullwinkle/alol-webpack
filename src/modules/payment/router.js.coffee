@Iconto.module 'payment', (Payment) ->

	class Payment.Router extends Iconto.shared.NamespacedRouter
		appRoutes:
			'payment(/)': 'payment'
			'payment(/)?order_id=:orderId': 'payment'