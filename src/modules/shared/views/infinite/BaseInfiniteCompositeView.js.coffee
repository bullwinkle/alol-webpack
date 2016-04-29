@Iconto.module 'shared.views.infinite', (Infinite) ->
	class Infinite.BaseInfiniteCompositeView extends Marionette.CompositeView

		behaviors:
			Layout:
				template: JST['shared/templates/mobile-layout']

			InfiniteScroll:
				scrollable: '.content-region'

		constructor: (options) ->
			options ||= {}

			superBehaviors = Infinite.BaseInfiniteCompositeView::behaviors
			if options.layout is false or options.layout is null
				superBehaviors = _.clone Infinite.BaseInfiniteCompositeView::behaviors
				delete superBehaviors.Layout

			@infiniteScrollState = new Backbone.Model
				limit: options.limit or @limit or 10
				offset: options.offset or @offset or 0
				loadByIds: options.loadByIds or @loadByIds or false #use this to load new items by prefetching ids and the slicing
			#internal
				complete: false
				isLoadingMore: false
				isEmpty: false

			if @infiniteScrollState.get('loadByIds')
				throw 'Loading by ids is not implemented yet'

			#first go base behaviors, then - specified in class extend and then - specified in options to view constructor
			@behaviors = _.extend {}, superBehaviors, @behaviors or {}, options.behaviors or {}

			super

		#public - override to provide custom params
		getQuery: =>
			return {}

		#public - call this function to start perloading on render
		preload: =>
			@_loadMore()
			.then =>
				if @$(@behaviors.InfiniteScroll.scrollable).prop('scrollHeight') <= @$(@behaviors.InfiniteScroll.scrollable).outerHeight() and not @infiniteScrollState.get('complete')
					_.defer =>
						@preload()

		#public - call this function to start perloading on render
		reload: =>
			@reset()
			@preload()

		#public - call this function to start perloading on render
		reset: =>
			@collection.reset()
			@infiniteScrollState.set
				complete: false
				offset: 0
				isEmpty: undefined

		#protected
		onInfiniteScroll: => #called from InfiniteScrollBehavior
			return false if @loadingLocked
			@loadingLocked = true
			@_loadMore()
			.then (response) =>
				@loadingLocked = false
				response

		#private
		_loadMore: =>
			Q.fcall =>
				state = @infiniteScrollState.toJSON()
				return false if state.complete

				@infiniteScrollState.set
					isLoadingMore: true
					isEmpty: undefined
				query = limit: state.limit, offset: state.offset
				_.extend query, @getQuery() #override to specify custom params
				@collection.fetchAll(query, {remove: false})
				.then (response) =>
					@infiniteScrollState.set 'complete', true if response.length < state.limit
					@infiniteScrollState.set
						isLoadingMore: false
						offset: state.offset + response.length #response.length - actual amount of loaded entities
						isEmpty: @collection.length is 0

					response