Iconto.module 'order', (Order) ->

	class Order.OrderRouter extends Iconto.shared.NamespacedRouter
		namespace: 'order'

		appRoutes:
			'(/)': 'index'
			'catalog(/)': 'showCatalog'
			'form-taxi(/)': 'showTaxiForm'
			'form-external(/)': 'showExternalForm'
			'restaurant-booking(/)': 'showRestaurantBooking'
			'booked-restaurants(/)': 'showBookedReataurants'

			'*other': 'pageNotFound'