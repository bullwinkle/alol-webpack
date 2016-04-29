@Iconto.module 'shared.services', (Services) ->
	getUserMedia = ->
		Modernizr.prefixed('getUserMedia', navigator)

	Services.media =

		available: !!getUserMedia()

		getSources: =>
			new Promise (resolve, reject) ->
				MediaStreamTrack.getSources resolve

		getUserMedia: getUserMedia()