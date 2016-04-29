@Iconto.module 'payment', (Payment) ->

	class Payment.Controller extends Marionette.Controller

		#payment(/)?order_id=:orderId
		payment: (orderId) =>
			orderId = Iconto.shared.helpers.navigation.getQueryParams()['order_id'] - 0 || 0;
			if orderId
				order = new Iconto.REST.Order id: orderId
				order.fetch()
				.then (order) =>
					Iconto.commands.execute 'workspace:show', new Payment.views.Layout(orderId: orderId, order: order)
#				.catch (error) =>
#					console.error error
#					Iconto.shared.views.modals.ErrorAlert.show error
				.done()