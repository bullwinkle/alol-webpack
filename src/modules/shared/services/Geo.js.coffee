@Iconto.module 'shared.services', (Services) ->
	setDefaultOptions = (options) ->
		options ||= {}
		options.enableHighAccuracy = true if _.isUndefined options.enableHighAccuracy
		options.maximumAge = 3 * 60 * 1000 if _.isUndefined options.maximumAge
		options

	Services.geo =

		ERROR_CODE_PERMISSION_DENIED: 1
		ERROR_CODE_POSITION_UNAVAILABLE: 2
		ERROR_CODE_TIMEOUT: 3

		available: navigator and navigator.geolocation

		getCurrentPosition: (options) ->
			new Promise (resolve, reject) ->
				navigator.geolocation.getCurrentPosition resolve, reject, setDefaultOptions(options)