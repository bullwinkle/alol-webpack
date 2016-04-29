@Iconto.module 'feedback', (Feedback) ->

	class Feedback.Router extends Iconto.shared.NamespacedRouter
		namespace: 'feedback'

		appRoutes:
			':addressSpotId(/)': 'feedback'