@Iconto.module 'shared.behaviors', (Behaviors) ->

	class Behaviors.InfiniteScroll extends Marionette.Behavior
		defaults:
			offset: 500
			inverted: false

		onRender: =>
			@scrollContainer = @_getScrollContainer()
			@scrollContainer.bind 'scroll.infinite-scroll-behavior', if @options.inverted then @onInvertedInfiniteScrollHandler else @onInfiniteScrollHandler

		onInfiniteScrollHandler: =>
			if @scrollContainer.prop('scrollHeight') - @scrollContainer.outerHeight() - @scrollContainer.scrollTop() <= @options.offset
				@view.onInfiniteScroll?.call @view
	#				@view.triggerMethod 'InfiniteScroll'

		onInvertedInfiniteScrollHandler: =>
			if @scrollContainer.scrollTop() <= @options.offset
				@view.onInfiniteScroll?.call @view
	#				@view.triggerMethod 'InfiniteScroll'

		onRequestInfiniteScroll: =>
			if @options.inverted then @onInvertedInfiniteScrollHandler() else @onInfiniteScrollHandler()

		_getScrollContainer: =>
			if @options.scrollable
				if _.isString @options.scrollable
					@$(@options.scrollable)
				else
					@options.scrollable
			else if @view.options.scrollable
				if _.isString @view.options.scrollable
					@$(@view.options.scrollable)
				else
					@view.options.scrollable
			else
				@$el

		onBeforeDestroy: =>
			@scrollContainer.unbind 'scroll.infinite-scroll-behavior'
			delete @scrollContainer