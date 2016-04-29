@Iconto.module 'shared.services', (Services) ->
	class Services.VirtualScrollDataProvider
		constructor: (query={}) ->
			@query = query
			@availableItems = null
			@items = null
			return @

		load: =>
			deferred = Promise.defer()
			if @availableItems
				deferred.resolve()
			else
		# this timeout only exists to give the loading indicator a chance to appear for demo purposes.
				setTimeout =>
					@availableItems = []
					i = 1
					while i < 1000
						@availableItems.push
							id: '' + i
							name: '' + i
						i++
					@items = @availableItems
					deferred.resolve()
					return
				, 1000
			deferred.promise

		filter : (search) =>
			if search.length > 0
				@items = _.filter(@availableItems, (item) ->
					item.name.indexOf(search) == 0
				)
			else
				@items = @availableItems
			return

		get: (firstItem, lastItem) =>
			@items.slice firstItem, lastItem

		size: =>
			@items.length

		identity: (item) =>
			item.id

		displayText: (item, extended) =>
			if item
				if extended then item.name + ' (' + item.id + ')' else item.name
			else
				''

		noSelectionText : =>
			'Please choose'

		getQuery: =>
			return @query || {}

	Services.virtualScrollDataProvider = new Services.VirtualScrollDataProvider