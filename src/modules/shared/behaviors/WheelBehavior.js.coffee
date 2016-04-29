@Iconto.module 'shared.behaviors', (Behaviors) ->
	#DEPRECATED! use [data-wheel-scroll] on scrollable elements
	class Behaviors._______Wheel extends Marionette.Behavior

		@AXIS_X = 1
		@AXIS_Y = 2
		@AXIS_XY = 3

		defaults:
			scrollable: '' #string selector
			axis: @AXIS_Y

		onRender: =>
			$('body').on "mousewheel.#{@view.cid}", (e) =>
				unless $(e.target).closest(@options.scrollable).get(0)
					$scrollable = @view.$(@options.scrollable)
					switch @options.axis
						when Behaviors.Wheel.AXIS_Y
							$scrollable.scrollTop $scrollable.scrollTop() - e.deltaY * e.deltaFactor
						when Behaviors.Wheel.AXIS_X
							$scrollable.scrollLeft $scrollable.scrollLeft() - e.deltaX * e.deltaFactor
						when Behaviors.Wheel.AXIS_XY
							$scrollable.scrollTop $scrollable.scrollTop() - e.deltaY * e.deltaFactor
							$scrollable.scrollLeft $scrollable.scrollLeft() - e.deltaX * e.deltaFactor
				undefined

		onBeforeDestroy: =>
			$('body').off "mousewheel.#{@view.cid}"
			undefined