@Iconto.module 'reg.views', (views) ->
	class views.Thanks extends Marionette.ItemView

		className: 'reg-thanks mobile-layout'
		template: JST['reg/templates/thanks/thanks']

		behaviors:
			Epoxy: {}
#			Layout:
#				template: JST['shared/templates/mobile-layout']

		# ui:

		# events:

		initialize: =>
			@state = new Iconto.reg.models.StateViewModel @options

		onRender: =>
			_.defer =>
				Iconto.api.logout()
				.then =>
					@state.set 'isLoading', false
				.done()