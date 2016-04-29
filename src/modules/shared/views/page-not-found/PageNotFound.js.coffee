@Iconto.module 'shared.views', (Views) ->

	class Views.PageNotFound extends Marionette.ItemView
		className: 'page-not-found mobile-layout'
		template: JST['shared/templates/page-not-found/page-not-found']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']


		initialize: =>
			@state = new Iconto.shared.models.BaseStateViewModel @options
			@state.set
				isLoading: false
				topbarTitle: 'Страницу украли злые роботы!'
