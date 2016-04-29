@Iconto.module 'shared.behaviors', (Behaviors) ->
	class Behaviors.OrderedCollection extends Marionette.Behavior

		initialize: (options, view) ->
			unless _.has view, 'attachHtml'
				view.attachHtml = (compositeView, childView, index) ->
					container = if @isBuffering then $(@elBuffer) else @getChildViewContainer(@)
					children = container.children()

					if children.size() <= index
						container.prepend childView.el
					else
						children.last().after childView.el