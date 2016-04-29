@Iconto.module 'operator.views', (Views) ->
	Views.factory = (state) ->
		ViewClass = switch state.page
			when 'chat'
				Views.BoardView
			else
				Views.BoardView

		unless ViewClass
			throw new Error("Unable to find view class for #{state.page} page")

		ViewClass