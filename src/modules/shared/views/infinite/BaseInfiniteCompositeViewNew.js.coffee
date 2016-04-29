@Iconto.module 'shared.views.infinite', (Infinite) ->

	class Infinite.BaseInfiniteCompositeViewNew extends Marionette.CompositeView

		behaviors:
#			Layout:
#				template: JST['shared/templates/mobile-layout']

			InfiniteScroll:
				scrollable: '.content-region'

		constructor: (options = {}) ->

			superBehaviors = Infinite.BaseInfiniteCompositeViewNew::behaviors
			if options.layout is false or options.layout is null
				superBehaviors = _.clone Infinite.BaseInfiniteCompositeViewNew::behaviors
				delete superBehaviors.Layout

			@infiniteScrollState = new Backbone.Model
				has_more: true
				token: options.token or @token or ''
				limit: options.limit or @limit or 10
			#internal
				complete: false
				isLoadingMore: false
				isEmpty: false

			#first go base behaviors, then - specified in class extend and then - specified in options to view constructor
			@options = options
			thisBehaviors = _.result(@,'behaviors',{})
			thisOptionsBehaviors = _.result(@,'options.behaviors',{})
			@behaviors = _.extend {}, superBehaviors, thisBehaviors, thisOptionsBehaviors
			super

		#public - override to provide custom params
		getQuery: =>
			return {}

		#public - call this function to start preloading on render
		preload: =>
			$scrollable = @$ @behaviors.InfiniteScroll.scrollable

			if !$scrollable.length # TODO remove this dirty hack
				$scrollable = $ @behaviors.InfiniteScroll.scrollable

			@_loadMore()
			.then =>
				if $scrollable.prop('scrollHeight') <= $scrollable.outerHeight() and not @infiniteScrollState.get('complete')
					_.defer @preload

		#public - call this function to reset collection and start preloading
		reload: =>
			@reset()
			_.defer =>
				@preload()

		reset: =>
			@collection.reset()
			@infiniteScrollState.set
				complete: false
				token: ''
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
				query = limit: state.limit, token: state.token
				_.extend query, @getQuery() #override to specify custom params
				query = _.pick(query, _.identity)
				@collection.fetch( query, {remove: false, cache: !!@options.cache})
				.then (response) =>
					pagination = _.get @,'collection._lastResponseMeta.pagination', {}
					@infiniteScrollState.set
						complete: !pagination.has_more
						isLoadingMore: false
						token: pagination.token
						isEmpty: @collection.length is 0

					response