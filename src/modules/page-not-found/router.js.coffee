@Iconto.module 'pageNotFound', (PageNotFound) ->

	class PageNotFound.Router extends Iconto.shared.NamespacedRouter
		appRoutes:
			'*other': 'indexPageNotFound'