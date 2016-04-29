@Iconto.module 'shared.regions', (Regions) ->

	class Regions.AnimatableRegion extends Marionette.Region
		defaults:
			visibleClass: 'is-visible'

		initialize: ->
			_.defaults(@options, @defaults )

			@initAnimationBehavior()

		initAnimationBehavior: =>
			show = @show
			return false unless show

			@show = (view) =>
				destroyView = view.destroy
				view.destroy = =>
					new Promise (resolve, reject) =>
						destroyArgs = arguments
						durationMs = 1000 * Math.max(
							parseFloat(@$el.css('animation-duration')),
							parseFloat(@$el.css('transition-duration'))
						)
						@hide()
						defer = =>
							resolve destroyView.apply view, destroyArgs
						setTimeout defer, durationMs+5

				show.apply @, arguments
				_.defer =>
					@$el.addClass @options.visibleClass

		hide: =>
			@$el.removeClass @options.visibleClass

		isVisible: =>
			@$el.hasClass @options.visibleClass