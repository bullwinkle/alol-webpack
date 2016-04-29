@Iconto.module 'oauth', (Oauth) ->
	class Oauth.Router extends Iconto.shared.NamespacedRouter
		namespace: 'oauth'

		appRoutes:
			'(/)': 'index'