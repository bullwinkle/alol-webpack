Iconto.module 'reg', (Reg) ->

	class Reg.Router extends Iconto.shared.NamespacedRouter
		namespace: 'reg'

		appRoutes:
			'(/)': 'showIndex'
			'terms(/)': 'regTerms'
			'tariffs(/)': 'regTariffs'
			'thanks(/)': 'showThanks'
