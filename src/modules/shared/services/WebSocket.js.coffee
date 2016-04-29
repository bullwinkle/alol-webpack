localStorage = window.localStorage || {}

@Iconto.module 'shared.services', (Services) ->

	class UnsentMessagesStorage
		unsentArray = null
		options:
			storageKeyName: 'unsentMessages'

		constructor: ->
			try
				unsentArray = JSON.parse localStorage[@options.storageKeyName]
			catch
				unsentArray = []
		get: =>
			return unsentArray

		push: (msg) =>
			unsentArray.push msg
			localStorage.unsentMessages = JSON.stringify unsentArray
			unsentArray.length

		pop: () =>
			res = unsentArray.pop()
			localStorage.unsentMessages = JSON.stringify unsentArray
			res

		shift: () =>
			res = unsentArray.shift()
			localStorage.unsentMessages = JSON.stringify unsentArray
			res


	class Services.WebSocket
		#private
		requestCounter = 0

		#static
		@STATUS_WEBSOCKET_DISCONNECTED = 'STATUS_WEBSOCKET_DISCONNECTED'
		@STATUS_WEBSOCKET_ERROR = 'STATUS_WEBSOCKET_ERROR'
		@STATUS_NO_INTERNET_CONNECTION = 'STATUS_NO_INTERNET_CONNECTION'
		@STATUS_SESSION_EXPIRED = 'SESSION_EXPIRED'
		@STATUS_INTERNAL_ERROR = 'INTERNAL_ERROR'

		@SILENT_EVENTS_LIST = SILENT_EVENTS_LIST = [
			'REQUEST_REST_PROXY',
			'request_echo'
		]
		@SAVE_MESSAGES_TYPES = SAVE_MESSAGES_TYPES = [
			'REQUEST_MESSAGE_CREATE',
			'REQUEST_MESSAGE_READ'
		]

		#public
		requests: {}

		subscriptions: {}

		unsentMessages: new UnsentMessagesStorage()

		wsoptions:
			url: window.ICONTO_WEBSOCKET_URL
			port: window.ICONTO_WEBSOCKET_PORT
			securePort: window.ICONTO_WEBSOCKET_SECURE_PORT

		constructor: (options) ->
			options ||= {}
			_.extend @wsoptions, options
			_.extend @, Backbone.Events

		connect: =>
			connectionDeferred = Promise.pending()

			connected = _.get(@, 'connection.socket.connected')
			connecting = _.get(@, 'connection.socket.connecting')
			reconnecting = _.get(@, 'connection.socket.reconnecting')
			reconnected = _.get(@, 'connection.socket.reconnecting')

			if connected or connecting or reconnecting
				connectionDeferred.resolve @connection
#				@connection.once 'connect', =>
#				@connection.once 'reconnect', => connectionDeferred.resolve @connection

			else if	_.get(@, 'connection.socket')
				@reconnect()
				.then =>
					@resendUnsentMessages()
				.then =>
					connectionDeferred.resolve @connection
				.catch (err) =>
					connectionDeferred.reject err

			else
				connectOptions =
					resource: 'websocket/socket.io'
					port: 443
					secure: true
					transports: [
						'websocket',
						'xhr-polling',
						'htmlfile'
					]

				@connection = io.connect @wsoptions.url, connectOptions

				@connection.once 'connect', =>
					console.info 'Websocket: connect -> connected', arguments
					console.info 'Websocket connected'
					@resubscribe()
					.then =>
						console.info 'Iconto.ws.resubscribe OK'
					.catch (error) =>
						console.error error
						switch error.status
							when WebSocket.STATUS_SESSION_EXPIRED
								options =
									from: 'services.WebSocket.connection.on("connect")'
								console.error WebSocket.STATUS_SESSION_EXPIRED
							else
								console.error 'Websockets - ', error
					.then =>
						@resendUnsentMessages()
					.done =>
						connectionDeferred.resolve @connection
						@trigger 'connected', @connection

				@connection.on 'disconnect', (error) =>
					console.warn 'Websocket: disconnected', arguments
					@trigger 'disconnected', @connection
					#reject all pending promises
					error ||= {}
					error.status = Services.WebSocket.STATUS_WEBSOCKET_DISCONNECTED
					for key, request of @requests
						delete @requests[key]

				@connection.on 'error', (error) =>
					console.warn 'Websocket: error', arguments
					@trigger 'error', error
					connectionDeferred.reject error

				@connection.on 'message', @onMessage

			connectionDeferred.promise

		reconnect: =>
			reconnectionDeferred = Promise.pending()

			connected = _.get(@, 'connection.socket.connected')
			connecting = _.get(@, 'connection.socket.connecting')
			reconnecting = _.get(@, 'connection.socket.reconnecting')
			reconnected = _.get(@, 'connection.socket.reconnecting')

			if _.get(@, 'connection.socket.reconnect')
				@connection.socket.once 'reconnect', =>
					console.warn 'Websocket: reconnected', arguments
					@trigger 'connected'
					@trigger 'reconnected'
					@resubscribe()
					.then =>
						console.info 'Iconto.ws.resubscribe OK'
						@resendUnsentMessages()
					.catch (error) =>
						console.error error
						switch error.status
							when WebSocket.STATUS_SESSION_EXPIRED
								options =
									from: 'services.WebSocket.connection.on("connect")'
								console.error WebSocket.STATUS_SESSION_EXPIRED
							else
								console.error 'Websockets - ', error
					reconnectionDeferred.resolve @connection
				@connection.socket.reconnect()
			else
				@connect()
				.then =>
					console.warn 'Websocket: reconnect -> connected', arguments
					@trigger 'connected'
					@resendUnsentMessages()
				.then =>
					reconnectionDeferred.resolve @connection
				.catch (err) =>
					reconnectionDeferred.reject err

			reconnectionDeferred.promise

		resendUnsentMessages: =>
			new Promise (resolve, reject) =>
				unsentMessages = @unsentMessages.get()
				unsentMessagesCount = unsentMessages.length

				send = (cb) =>
					msg = @unsentMessages.shift()
					if !msg then return cb()
					setTimeout =>
						@connection.json.send msg
						send(cb)
					, 1000

				send =>
					console.info 'All unsent messages sent'
					resolve('ok')

		disconnect: =>
			@off()
			delete @requests[key] for key in @requests
			delete @subscriptions[key] for key in @subscriptions
			connected = _.get(@, 'connection.socket.connected')
			connecting = _.get(@, 'connection.socket.connecting')
			reconnecting = _.get(@, 'connection.socket.reconnecting')
			reconnected = _.get(@, 'connection.socket.reconnecting')
			if @connection?.socket and ( connected or connecting or reconnecting )
				@connection.disconnect()

#		emit: (event, data) =>
#			[module, resource, eventName] = event.split(':')
#			if module and resource and eventName
#
#				message =
#					module: module
#					resource: resource
#					event: eventName
#					data: data || {}
#					sid: @wsoptions.sid
#
#				console.log 'WS: sending', event, message
#				@connection.json.send message

		ping: (data) =>
			data ||= {}
			deferred = Promise.pending()
			messageId = ++requestCounter

			message =
				message_id: messageId
				data_type: 'request_echo'
				data: data
			time = new Date().getTime()
			@requests[messageId] =
				sent_at: time
				request: message
				promise: deferred

			promise = deferred.promise.cancellable()
			if @connection and @connection.socket and @connection.socket.connected
				@connection.json.send message
			promise

		action: (name, data) =>
			data ||= {}
			deferred = Promise.pending()
			messageId = ++requestCounter

			unless name is 'REQUEST_REST_PROXY'
				console.log 'WS: ACTION', name, _.clone data

			message =
				message_id: messageId
				data_type: name
				data: data
			time = new Date().getTime()
			@requests[messageId] =
				sent_at: time
				request: message
				promise: deferred

			promise = deferred.promise.cancellable()
#			if @connection and @connection.socket and @connection.socket.connected
			@connection.json.send message
			if !Iconto.mary.connected and name in SAVE_MESSAGES_TYPES
				@unsentMessages.push message

#			else
#				#reject all pending promises
#				for key, request of @requests
#					delete @requests[key]
#					request.promise.reject
#						status: services.WebSocket.STATUS_NO_INTERNET_CONNECTION
#				deferred.reject
#					status: services.WebSocket.STATUS_NO_INTERNET_CONNECTION

			promise

		emit: (name, data) =>
			data ||= {}
			messageId = ++requestCounter
			message =
				message_id: messageId
				data_type: name
				data: data
			console.log 'WS: EMIT', name, _.clone data
			if @connection and @connection.socket and @connection.socket.connected
				@connection.json.send message

	#	request: (module, resource, event, data) =>
		request: (event, data) =>
			d = $.Deferred()

			[module, resource, eventName] = event.split(':')

			if module and resource and eventName

				requestCounter++ #synchronized
				message =
					id: requestCounter
					module: module
					resource: resource
					event: eventName
					data: data || {}
#					sid: @wsoptions.sid
				time = new Date().getTime()
				@requests[message.id] =
					sent_at: time
					request: message
					handler: (response) =>
						delete @requests[message.id]
						if response.data.error
							d.reject response.data.error
						else
							d.resolve response.data

				console.log 'WS: sending', event, message, time
				@connection.json.send message

			else
				throw new Error('Unknown module, resource or eventName')

			d.promise()

		subscribe: (event, data, callback) =>
			@action('REQUEST_SUBSCRIBE', _.extend type: "SUBSCRIPTION_#{event.toUpperCase()}", data)
			.then (response) =>
				@subscriptions[response.route] =
					event: event
					data: data
				@on "#{event}.#{response.route}", callback
				response

		unsubscribe: (route) =>
			subscription = @subscriptions[route]
			delete @subscriptions[route]
			event = subscription.event
			@off "#{event}.#{route}"
			@action('REQUEST_UNSUBSCRIBE', _.extend({type: "SUBSCRIPTION_#{event.toUpperCase()}", route: route}, subscription.data))

		_old_resubscribe: =>
			requests = for route, subscription of @subscriptions
				@action('REQUEST_RESUBSCRIBE', route: route)
			Q.all requests

		resubscribe: =>
			requests = for route, subscription of @subscriptions
				@action('REQUEST_SUBSCRIBE', _.extend
					route: route,
					type: "SUBSCRIPTION_#{subscription.event.toUpperCase()}",
					subscription.data
				)
			Q.all requests

		onMessage: (message) =>
			switch message.message_type
				when 'response'
					@parseResponse(message)
				when 'event'
					@parseEvent(message)
				else
					console.error 'WS: UNKNOWN', message

		parseResponse: (message) =>
			time = new Date().getTime()
			requestData = @requests[message.message_id]

			messageAttachments = _.get(message, "data.message.attachments", [])
			collectionAttachments = _ _.get(message, "data.messages", [])
			.map (msg) -> msg.attachments
			.compact()
			.value()

			if messageAttachments.length
				console.groupCollapsed('Message attachments')
#				console.warn "MESSAGE ATTACHMENTS\n############################"
				console.log messageAttachments
				console.log JSON.stringify messageAttachments, null, '\t'
#				console.warn "\n############################"
				console.groupEnd('Message attachments')

			if collectionAttachments.length
				console.groupCollapsed('Collection attachments')
#				console.warn "COLLECTION ATTACHMENTS\n############################"
				console.log collectionAttachments
				console.log JSON.stringify collectionAttachments, null, '\t'
#				console.warn "\n############################"
				console.groupEnd('Collection attachments')

			delete @requests[message.message_id]
			unless requestData
				console.error "WS: cannot find handler for response", message
			else
				switch message.data_type
					when 'error_message'
						error =
							status: message.data.code
							msg: message.data.text
						requestData.promise.reject error
						unless requestData.request.data_type in SILENT_EVENTS_LIST
							console.log "WS: ACTION #{requestData.request.data_type} RESPONSE ERROR", requestData.request.data, error, time - requestData.sent_at

						switch error.status
							when WebSocket.STATUS_SESSION_EXPIRED
								options =
									from: 'services.WebSocket.parseResponse'
								console.error WebSocket.STATUS_SESSION_EXPIRED
#								return Iconto.commands.execute 'error:user:unauthorised', error, options
#								return console.warn 'Websockets - user unauthorised'

					else
						requestData.promise.fulfill(message.data)
						unless requestData.request.data_type in SILENT_EVENTS_LIST
							console.log "WS: ACTION #{requestData.request.data_type} RESPONSE", requestData.request.data, message.data, time - requestData.sent_at


		parseEvent: (message) =>
			console.log 'WS: EVENT', message
			messageAttachments = _.get(message, "data.message.attachments", [])
			collectionAttachments = _ _.get(message, "data.messages", [])
			.map (msg) -> msg.attachments
			.compact()
			.value()

			if messageAttachments.length
				console.groupCollapsed('Message attachments')
#				console.warn "MESSAGE ATTACHMENTS\n############################"
				console.log messageAttachments
				console.log JSON.stringify messageAttachments, null, '\t'
#				console.warn "\n############################"
				console.groupEnd('Message attachments')

			if collectionAttachments.length
				console.groupCollapsed('Collection attachments')
#				console.warn "COLLECTION ATTACHMENTS\n############################"
				console.log collectionAttachments
				console.log JSON.stringify collectionAttachments, null, '\t'
#				console.warn "\n############################"
				console.groupEnd('Collection attachments')


			@trigger "#{message.data_type.toUpperCase()}.#{message.data.route}", message.data