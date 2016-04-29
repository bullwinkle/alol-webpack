@Iconto.module 'shared', (Shared) ->

	show = (View, options = {}) ->
		App.workspace.show new View options


	class Shared.SharedController

		orderForm: =>
			show Shared.views.orders.OrderFormLayout

		pageNotFound: =>
			show Shared.views.PageNotFound