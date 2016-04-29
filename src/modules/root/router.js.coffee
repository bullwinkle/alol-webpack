@Iconto.module 'root', (Root) ->
	class Root.Router extends Iconto.shared.NamespacedRouter
		appRoutes:
			'(/)': 'indexRoute'

		#wrt
#			'signup': 'wrtSignup'
#			'signin': 'wrtSignin'