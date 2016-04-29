Iconto.module 'reg', (Reg) ->

	updateWorkspace = (params) ->
		Iconto.commands.execute 'workspace:update', Reg.views.Layout, params

	class Reg.Controller extends Marionette.Controller

		#reg/
		showIndex: =>
			updateWorkspace
				page: 'registration'

		#reg/terms
		regTerms: =>
			updateWorkspace
				page: 'terms'
				subpage: 'reg'

		#reg/tariffs
		regTariffs: =>
			updateWorkspace
				page: 'tariffs'
				subpage: 'reg'

		#reg/thanks
		showThanks: =>
			updateWorkspace
				page: 'thanks'
				