#= require ./SearchResults

@Iconto.module 'root.views.wrt', (Wrt) ->
	class Wrt.Layout extends Marionette.LayoutView
		template: JST['root/templates/wrt/layout']
		className: 'wrt-layout'

		behaviors:
			Epoxy: {}
			InfiniteScroll:
				scrollable: '.search-results-region'

		ui:
			form: 'form[name=input-form]'
			input: 'input[name=company-name]'
			cancelButton: '.cancel'
			clearButton: '.clear'
			searchButton: '.search'

		events:
			'submit @ui.form': 'onFormSubmit'
			'click @ui.cancelButton': 'onCancelButtonClick'
			'click @ui.clearButton': 'onClearButtonClick'
			'click @ui.searchButton': 'onSearchButtonClick'

#			'input @ui.input': 'onSearchInput'

		regions:
			searchResultsRegion: '.search-results-region'

		addressCollectionResource: new Iconto.REST.AddressCollection()

		initialize: =>
			@scroll =
				bottomOffset: 200
				locked: false
				offset: 0
				limit: 15

		onRender: =>
			$('#workspace').addClass('wrt')

			searchResultsView = new Wrt.SearchResults
				collection: new Iconto.REST.AddressCollection()
			@searchResultsRegion.show searchResultsView

			$(window).bind 'scroll', =>
				if $(window).scrollTop() + $(window).height() - $(document).height() > -@scroll.bottomOffset
					@onScroll()

		onBeforeDestroy: =>
			$('#workspace').removeClass('wrt')
			$(window).unbind 'scroll'

		onFormSubmit: (e) =>
			e.preventDefault()
			e.stopPropagation()

			@ui.input.blur()
			@$el.addClass('searching')

			@clearResults()

			searchString = @ui.input.val().trim()
			@search searchString

		onSignupClick: =>
			@$el.removeClass('searching')

		onCancelButtonClick: =>
			@$el.removeClass('searching')
			@ui.input.val('')
			@clearResults()

		onClearButtonClick: =>
			@ui.input.val('').focus()
			@clearResults()

		onSearchButtonClick: =>
			searchString = @ui.input.val().trim()

			if searchString
				@ui.input.blur()
				@$el.addClass('searching')
				@search(searchString)
			else
				@ui.input.focus()

		clearResults: =>
			@scroll.locked = false
			@scroll.offset = 0
			@searchResultsRegion.currentView.collection.reset()

		onScroll: =>
			if @$el.hasClass('searching')
				searchString = @ui.input.val().trim()
				@search searchString

		search: (value) =>
			unless @scroll.locked
				@scroll.locked = true
				@$('.search-results').addClass('is-loading')

				params =
					query: value
					limit: @scroll.limit
					offset: @scroll.offset

				@addressCollectionResource.fetchAll(params)
				.then (addresses) =>
					@searchResultsRegion.currentView.collection.add addresses

					@scroll.offset = @scroll.offset + @scroll.limit
					@scroll.locked = false

					if addresses.length < @scroll.limit
						@scroll.locked = true
				.catch (error) =>
					console.error error
				.done =>
					@$('.search-results').removeClass('is-loading')