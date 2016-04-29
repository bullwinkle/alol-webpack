@Iconto.module 'pageNotFound.views', (PageNotFound) ->

	class PageNotFound.PageNotFound extends Marionette.ItemView
		className: 'page-not-found'
		template: JST['page-not-found/templates/page-not-found']