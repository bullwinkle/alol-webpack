@Iconto.module 'shared.services', (Services) ->

	class Services.Intercom extends Intercom

		#------------ private ------------

		isMyMessage = (message, origin) ->
			if message.options?.fromOrigin is origin
				return true
			else
				return false

		constructor: ->
			super()

			eventOptions =
				origin: @origin

			for event, handler of intercomController
				unless _.isFunction(handler)
					console.warn "Intercom handler for \"#{event}\" is not a function"
					continue
				do (event, handler) =>
					handler = handler.bind(@)
					@on event, (message) =>
						return false if isMyMessage message, @origin
						console.info "INTERCOM: #{event}", message
						handler(message)

		#------------ public ------------

		emit: (event="", message={}) =>
			message =
				options:
					fromOrigin: @origin
				data: message

			super event, message

	intercomController =
		login: (message) ->
#			Iconto.shared.router.complete Iconto.defaultAuthorisedRoute

		logout: (message) ->
			Iconto.shared.router.action Iconto.defaultUnauthorisedRoute

		unauthorised: (message) =>
#			Iconto.commands.execute 'error:user:unauthorised'

		authorised: (message) =>
#			Iconto.commands.execute 'modals:closeAll'
