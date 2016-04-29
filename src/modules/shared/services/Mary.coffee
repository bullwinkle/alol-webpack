###
REQUIRED:
	alertify
	jQuery.ajax
	Iconto.events
	Iconto.api
	Iconto.ws

TRIGGERS:
	internetConnection:lost
	internetConnection:found
	authorised:false
	authorised:true
###

@Iconto.module 'shared.services', (Services) ->

	class Services.Mary

		# private
		__singleton = null

		connected: true

		options:
			checkSessionInterval: 5*60*1000 # 5 min
			checkConnectionInterval: 5000 # 5 sec
			serverUnavailableTimeLimit: 1*60*1000 # 1min
			checkConnectionTimeout: 10000 # max time to get responce from server
			sessionLostWebSocketDisconnectTimeout: 60000 # 60 sec - time of socket.io heartbeat

		messages:
			connectionLost: "Потеряно соединение с чат-сервером"
			connectionRestored: "Соединение с чат-сервером восстановлено"

		_checkSessionTimeout:  0
		_checkConnectionInterval:  0
		_serverUnavailableTimeout: 0
		noInternetConnectionNotification: null

		constructor: ->
			return __singleton if __singleton
			__singleton = @

		initialize: =>
			@updateCheckConnectionInterval()

		updateCheckConnectionInterval: =>
			if @_checkConnectionInterval then clearTimeout @_checkConnectionInterval
			@_checkConnectionInterval = setInterval @checkConnection, @options.checkConnectionInterval

		updateCheckSessionTimeout:  =>
			if @_checkSessionTimeout then clearTimeout @_checkSessionTimeout
			@_checkSessionTimeout = setTimeout @checkSession, @options.checkSessionInterval

		checkSession: (cb) =>
#			console.info('checkSession', moment().format('HH:mm:ss'))
			Iconto.api.get('auth')
			.then (data) =>
				if !_.get(data, 'user_id')
					clearTimeout @_checkSessionTimeout
					Iconto.events.trigger 'authorised:false'
					Iconto.api.authorized = false
					# disconnect websockets after [@options.sessionLostWebSocketDisconnectTimeout] if still not authorized
					setTimeout =>
						return if Iconto.api.authorized and Iconto.api.userId is Iconto.api.lastAuthorizedUserId
						Iconto.ws.disconnect()
					,@options.sessionLostWebSocketDisconnectTimeout
				else
					Iconto.events.trigger 'authorised:true'
					Iconto.ws.connect()

			.catch (err) =>
				console.warn 'session expired',err
			.done () =>
				@updateCheckSessionTimeout()

		checkConnection: =>
#			console.info('checkConnection', moment().format('HH:mm:ss'))

			return false unless Iconto.api.authorized

			@ping()
			.then (pong) =>
				_.set Iconto,'isOnline', pong
				@connected = pong
				if pong
					Iconto.events.trigger 'internetConnection:found'
					if @_serverUnavailableTimeout
						@_serverUnavailableTimeout = 0

					if @noInternetConnectionNotification and !@noInternetConnectionNotification._dismissed
						@noInternetConnectionNotification._dismissed = true
						@noInternetConnectionNotification.ondismiss = => delete @noInternetConnectionNotification
						@noInternetConnectionNotification
						.setContent(@messages.connectionRestored)
						.delay 6 # sec
				else
					console.warn @messages.connectionLost
					Iconto.events.trigger 'internetConnection:lost'

					# note the time if lost connection detected at first time
					unless @_serverUnavailableTimeout
						@_serverUnavailableTimeout = +(new Date())
					else # if lost connection detected NOT at first time
						currentTime = +(new Date())
						# check how many time ago lost connection detected at first time
						# show notification if more then set in @options.serverUnavailableTimeLimit
						if (currentTime - @_serverUnavailableTimeout) >= @options.serverUnavailableTimeLimit
							if @noInternetConnectionNotification
								@noInternetConnectionNotification
								.setContent(@messages.connectionLost)
								.delay(0)
								@noInternetConnectionNotification._dismissed = false
							else
								@noInternetConnectionNotification = alertify.error(@messages.connectionLost, 0)

				pong

			.catch (err) =>
				# only unexpectable shit here
				console.error 'checkConnection error', err

		ping: =>
			new Promise (resolve, reject) =>
				unless navigator.onLine
					resolve(false)
				else
					promiseTimeout = setTimeout =>
						resolve(false)
					, @options.checkConnectionTimeout

					Iconto.ws.ping
						text: JSON.stringify
							time: new Date().toString()
					.then (res) =>
						res.text = JSON.parse(res.text)
						clearTimeout promiseTimeout
						resolve(true)
					.catch (err) =>
						clearTimeout promiseTimeout
						resolve(false)
					.done()
