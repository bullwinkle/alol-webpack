@Iconto.module 'wallet.views.about', (About) ->
	class About.AboutItemView extends Marionette.ItemView
		className: 'about-layout mobile-layout'
		template: JST['wallet/templates/about/about']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		ui:
			topbarLeftButton: '.topbar-region .left-small'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'

		initialize: =>
			@state = new Iconto.wallet.models.StateViewModel _.extend {}, @options,
				isLoading: false

				breadcrumbs: [
					{title: 'Профиль', href: '/wallet/profile'}
					{title: 'Алоль', href: '/wallet/about'}
				]

		onTopbarLeftButtonClick: =>
			defaultRoute = Backbone.history.fragment.split('/').slice(0, 2).join('/')
			parsedUrl = Iconto.shared.helpers.navigation.parseUri()
			fromRoute = _.get parsedUrl, 'query.from'
			route = fromRoute or defaultRoute
			Iconto.shared.router.navigate route, trigger: true