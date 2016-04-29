@Iconto.module 'root.views.wrt', (Wrt) ->

	class Wrt.SearchResultsItem extends Marionette.ItemView
		template: JST['root/templates/wrt/search-results-item']
		className: 'search-results-item'

		onRender: =>
			@$el.data('address-id', @model.get('id'))
			@$('a').attr('href', "/#{@model.get('id')}")

	class Wrt.SearchResults extends Marionette.CollectionView
		className: 'search-results'
		childView: Wrt.SearchResultsItem