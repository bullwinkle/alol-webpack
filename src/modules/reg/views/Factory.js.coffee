@Iconto.module 'reg.views', (Views) ->

	Views.factory = (state) ->
		ViewClass = switch state.page

			when 'registration'
				Views.Registration

			when 'terms', 'tariffs'
				Views.TermsView

			when 'thanks'
				Views.Thanks
				
		unless ViewClass
			throw new Error("Unable to find view class for #{state.page} page")

		ViewClass
