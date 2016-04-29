localStorage = window.localStorage || {}

$.ajaxSetup
	crossDomain: true
	dataType: 'json'
	contentType: 'application/json'
	xhrFields:
		withCredentials: true
	headers:
		'X-Suppress-HTTP-Code': '1'

post = $.post
$.post = (url, data, callback, type) ->
	data = JSON.stringify(data) if _.isObject(data)
	post.call @, url, data, callback, 'json'

$.ajaxPrefilter (options) ->
	unless options.url.match(/^\w*:\/\//)
		options.url = "#{window.ICONTO_API_URL}#{options.url}"
	options

logResponse = (response) =>
	authorized = !!response.user_id
	forbidden = response.status is Iconto.REST.User.STATUS_FORBIDDEN
	error = not response.status in [0, Iconto.REST.User.STATUS_UNAUTHORIZED]
	console.log '\n'
	console.info 'authorized:', authorized
	console.warn 'forbidden:', forbidden
	console.error 'error:', error
	console.log '\n'

mary = Iconto.mary
mary.initialize()

handleGlobalErrors = (promise) ->
	mary.updateCheckSessionTimeout()
	promise
	.then (response) ->
		authorized = !!response.user_id
		forbidden = response.status is Iconto.REST.User.STATUS_FORBIDDEN
		error = response.status isnt 0

#		logResponse(response)

		if authorized
			Iconto.api.authorized = true
			Iconto.api.userId = response.user_id
		else
			Iconto.api.authorized = false
			Iconto.api.userId = null
			Iconto.api.currentUser = null
#			Iconto.ws.disconnect()
			# TODO: remove if not necessary
#			response.status = Iconto.REST.User.STATUS_UNAUTHORIZED
			Iconto.commands.execute 'workspace:unauthorised'

		if error or forbidden
			throw response

		response

handleWebSocketErrors = (promise) ->
	promise
	.catch (error) ->
		console.error error
		WebSocket = Iconto.shared.services.WebSocket
		switch error.status
			when WebSocket.STATUS_SESSION_EXPIRED
				promise.cancel().done()
		#				if Iconto.api.userId
		#					options =
		#						from: 'handleWebSocketErrors'
		#					Iconto.commands.execute 'workspace:unauthorised'
		#					Iconto.commands.execute 'error:user:unauthorised', error, options
			else
				throw error

http =
	authorized: false
	get: (url, query) ->
		handleGlobalErrors Q $.get url, query
	post: (url, data) ->
		handleGlobalErrors Q $.post url, data
	put: (url, data) ->
		options =
			type: 'PUT'
			url: url
		options.data = JSON.stringify(data) if data
		handleGlobalErrors Q $.ajax options
	'delete': (url, query) ->
		unless _.isEmpty(query)
			url += "?#{$.param(query)}"
		options =
			type: 'DELETE'
			url: url
		handleGlobalErrors Q $.ajax options
	options: (url) ->
		options =
			type: 'OPTIONS'
			url: url
		handleGlobalErrors Q $.ajax options

	connect: ->
		Iconto.ws.connect()

	lastAuth: 0
	authCounter: 0
	auth: ->
		# prevent infinite loop
		now = Date.now()
		if @lastAuth > 0
#			console.warn "Iconto.api.auth():"
#			console.warn " - #{@authCounter} times in a row"
#			console.warn " - #{now - @lastAuth}ms from last time"
			if now - @lastAuth <  100
				@authCounter++
			else
				@authCounter = 0
		@lastAuth = now
		if @authCounter > 20
			return new Promise (resolve,reject) => reject {}

		Q.fcall =>
			if @userId
				userModel = (new Iconto.REST.User(id: @userId))

				@connect()

				userModel.fetch()
				.then (user) =>
#					# ATTENTION !!!!
					unless user.settings
						userModel.invalidate()
						return @auth()

					@currentUser = user
					@authorized = true
					@lastAuthorizedUserId = @userId
					@sessionExpired = false
					Iconto.commands.execute 'workspace:authorised'
					user
			else
				@get('auth')
				.then (response) =>
					userId = response.user_id or response.data.userId
					if userId
						@userId = userId
						@auth()
					else
#						Iconto.commands.execute 'workspace:unauthorised'
						delete @userId
						throw status: Iconto.REST.User.STATUS_UNAUTHORIZED


	login: (login, password, companyId = null) ->
		authData =
			login: login
			password: password
		authData.company_id = companyId if companyId

		@post('auth', authData)
		.then (res) =>
			console.warn(res)
			res.data ||= {}

			userId = res.user_id or res.data.userId
			if !userId then	throw res
			else @userId = userId

			@auth()

	logout: ->
		delete Iconto.REST.cache[key] for key of Iconto.REST.cache
		@post('auth?_method=delete')
		.then =>
			@authorized = false
			@userId = null
			@currentUser = null
			Iconto.ws.disconnect()
			window.localStorage.clear()
			Iconto.commands.execute 'workspace:unauthorised'
			Iconto.intercom.emit('logout', {userId: @userId})
			true #do not wait for refresh()

proxy = (options) ->
	request = _.clone(options)

	#attach cookie
	if options.path.indexOf('sid=') is -1 #sid is absent
		#sid = $.cookie window.ICONTO_API_SID
		if sid
			if options.path.indexOf('?') is -1 #if query string is absent
				options.path += '?'
			else
				options.path += '&'
			options.path += "sid=#{sid}"

	console.log 'PROXY:', request
	options.payload = JSON.stringify(options.payload) if options.payload

	start = new Date().getTime()
	Iconto.ws.action('REQUEST_REST_PROXY', options)
	.then (response) ->
		result = JSON.parse response.data
		console.log 'PROXY: RESPONSE', request, result, new Date().getTime() - start
		result

websocket =
	authorized: false
	get: (url, query) ->
		unless _.isEmpty(query)
			url += "?#{$.param(query)}"
		handleGlobalErrors handleWebSocketErrors proxy method: 'get', path: url
	post: (url, data) ->
		handleGlobalErrors handleWebSocketErrors proxy method: 'post', path: url, payload: data
	put: (url, data) ->
		handleGlobalErrors handleWebSocketErrors proxy method: 'put', path: url, payload: data
	'delete': (url, query) ->
		if query and not _.isEmpty(query)
			url += "?#{$.param(query)}"
		handleGlobalErrors handleWebSocketErrors proxy method: 'delete', path: url
	options: (url, query) ->
		if query and not _.isEmpty(query)
			url += "?#{$.param(query)}"
		handleGlobalErrors handleWebSocketErrors proxy method: 'options', path: url

	connect: ->
		Iconto.ws.connect()

	refresh: ->
		handleWebSocketErrors Iconto.ws.action('REQUEST_CONNECTION_REFRESH')

	auth: ->
		Q.fcall =>
			@get('user')
			.then (response) ->
				@userId = response.user_id

				if @userId
					(new Iconto.REST.User(id: @userId)).fetch()
					.then (user) =>
						@authorized = true
						user
				else
					throw status: Iconto.REST.User.STATUS_UNAUTHORIZED

	login: (login, password) ->
		@post('auth', login: login, password: password)
		.then (response) =>
			@authorized = true
			@refresh()
			.then =>
				response

	logout: ->
		delete Iconto.REST.cache[key] for key of Iconto.REST.cache
		@['delete']('auth')
		.then (response) =>
			@authorized = false
			@userId = null
			window.localStorage.clear()
			@refresh()

Iconto.api = switch window.ICONTO_CURRENT_TRANSPORT
	when window.ICONTO_TRANSPORTS.HTTP
		http
	when window.ICONTO_TRANSPORTS.WEBSOCKET
		websocket

#do not use without strong purpose!
#placed here for backwards compatibility
Iconto.api.http = http
Iconto.api.websocket = websocket

Iconto.api.userId = null
Iconto.api.lastAuthorizedUserId = null
Iconto.api.userUnauthorisedLock = false
Iconto.api.sessionExpired = false
