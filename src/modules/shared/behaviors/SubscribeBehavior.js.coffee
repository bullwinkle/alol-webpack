@Iconto.module 'shared.behaviors', (Behaviors) ->
	class Behaviors.Subscribe extends Marionette.Behavior
#		default:
#			example:
#				event:
#					args: {}
#					handler: ''

		subscribe: (event, args, handler) =>
			Iconto.ws.subscribe(event, args, handler)
			.then (response) =>
				@subscriptions.push response.route
			.dispatch(@view)
			.catch (error) =>
				console.error error
#				if error.status isnt Iconto.shared.services.WebSocket.STATUS_SESSION_EXPIRED
#					Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		unsubscribeAll: =>
			promises = (while route = @subscriptions.pop()
				Iconto.ws.unsubscribe(route))
			Q.all promises

		initialize: (options, view) =>
			@subscriptions = []
			@view.subscribe = @subscribe
			@view.unsubscribeAll = @unsubscribeAll

		onRender: =>
			_.defer => #subscribe only after all onRender handlers
				for event, data of @options
					if _.isFunction(data.args)
						args = data.args.call(@view)
					else
						args = data.args
					@subscribe(event, args, @view[data.handler])
			undefined

		onBeforeDestroy: =>
			@unsubscribeAll()
			.catch (error) =>
				console.error error
				unless error.status is Iconto.shared.services.WebSocket.STATUS_SESSION_EXPIRED
					Iconto.shared.views.modals.ErrorAlert.show error
			.done()
