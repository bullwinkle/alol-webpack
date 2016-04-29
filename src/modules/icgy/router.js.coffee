@Iconto.module 'icgy', (Icgy) ->

	class Icgy.Router extends Iconto.shared.NamespacedRouter
		namespace: 'icgy'

		appRoutes:
			'(/)': 'index'