@Iconto.module 'operator', (Operator) ->
	class Operator.Router extends Iconto.shared.NamespacedRouter
		namespace: 'operator'

		appRoutes:
			'(/)': 'index'
			'chat/:chatId(/)': 'chat'
			'*other(/)': 'redirect'

		route: (route, name, callback) ->
			super route, name, =>
				routeArguments = Array::slice.call arguments
				Iconto.api.auth()
				.then (user) =>
					callback.apply(@, routeArguments)
				.catch (error) =>
					@action 'auth'
				.done()