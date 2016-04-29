@Iconto.module 'order.views', (Views) ->

	Views.factory = (options) ->
		ViewClass = switch options.page

			when 'taxi'
				Views.TaxiFormView
			when 'external'
				Views.ExternalFormView
			when 'catalog'
				Views.ShopLayout
			when 'restaurant-booking'
				Views.RestaurantBooking
			when 'booked-restaurants'
				Views.BookedRestaurants
			else
				# 'default'
				Views.DefaultOrder

		unless ViewClass
			throw new Error("Unable to find view class for #{state.page} page")
		ViewClass
