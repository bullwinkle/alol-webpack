#= require ./BaseModal

@Iconto.module 'shared.views.modals', (Modals) ->

	class Modals.Confirm extends Modals.BaseModal
		className: 'confirm'

		template: JST['shared/templates/modals/confirm']

		cancelEl: '[name=cancel]'
		submitEl: '[name=ok]'

		initialize: (options) =>
			@model = new Modals.BaseModel options

		@show: (options) ->
			confirm = new Modals.Confirm options
			confirm.show()
			confirm