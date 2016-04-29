#= require shared/views/modals/Alert

@Iconto.module 'shared.views.modals', (Modals) ->

	class Modals.ErrorAlert extends Modals.Alert
		template: JST['shared/templates/modals/error-alert']

		initialize: (options) =>
			@willShow = true
			params = title: "Произошла ошибка"
			if options.status is 'SESSION_EXPIRED'
				console.warn 'SESSION_EXPIRED error muted'
				@willShow = false

			if not _.isUndefined(options.status) and not _.isUndefined(options.msg)
				#server-side options
				params.message = options.msg
				params.status = options.status
			else
				if options.message
					text = options.message
				else if options instanceof Error
					text = options.toString()
				else
					text = JSON.stringify options, null, 4
				params.message = text
			super _.extend params, options

		@show = (error) =>
			alert = new Modals.ErrorAlert error
			return unless alert.willShow
			alert.show()
			alert