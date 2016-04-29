Iconto.module 'order', (Order) ->

	show = (View, options = {}) ->
		App.workspace.show new View options

	updateWorkspace = (params={}) ->
		Iconto.commands.execute 'workspace:update', Order.views.OrderFormLayout, params

	class Order.OrderController

		index: =>
			updateWorkspace
				page: 'default'

		showCatalog: =>
			updateWorkspace
				page: 'catalog'

		showTaxiForm: =>
			updateWorkspace
				page: 'taxi'

		showExternalForm: =>
			updateWorkspace
				page: 'external'

		showRestaurantBooking: =>
			updateWorkspace
				page: 'restaurant-booking'

		showBookedReataurants: =>
			updateWorkspace
				page: 'booked-restaurants'

		pageNotFound: =>
			show Iconto.shared.views.PageNotFound