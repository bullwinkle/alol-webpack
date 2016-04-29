@Iconto.module 'shared.services', (Services) ->

	Services.vibration =
		vibrate: (duration) ->
			navigator.vibrate?(duration)