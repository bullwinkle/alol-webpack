#= require ./BaseModal

@Iconto.module 'shared.views.modals', (Modals) ->

	class AlertModel extends Modals.BaseModel
	_.extend AlertModel::defaults,
		status: ''

	class Modals.Alert extends Modals.BaseModal
		className: 'alert'

		template: JST['shared/templates/modals/alert']

		cancelEl: '[name=ok]'

		initialize: (options) =>
			@model = new AlertModel(options)

		@show: (options) ->
			alert = new Modals.Alert options
			alert.show()
			alert