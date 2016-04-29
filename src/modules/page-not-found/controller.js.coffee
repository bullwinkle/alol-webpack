@Iconto.module 'pageNotFound', (PageNotFound) ->

	class PageNotFound.Controller extends Marionette.Controller

		#(/*other)
		indexPageNotFound: ->
			Iconto.commands.execute 'workspace:update', PageNotFound.views.PageNotFound

			regexpRoute = Backbone.Router::_routeToRegExp('*other').toString()

			findOther = _.find Backbone.history.handlers, (handler) ->
				`handler.route == regexpRoute`

			if findOther
				indexOther = _.indexOf Backbone.history.handlers, findOther
				if indexOther isnt -1
					Backbone.history.handlers.splice indexOther, 1
					Iconto.shared.Loader.unload 'pageNotFound'