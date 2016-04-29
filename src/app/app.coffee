#= require_self

window.App = App = @iContoApplication = new Marionette.Application()

App.on 'start', =>
	console.info 'APPLICATION: initializing'
#	App.addRegions
#		workspace: new Iconto.shared.views.updatableregion.UpdatableRegion(el: '#workspace')
#		modals:
#			selector: '#modals'
#			regionClass: Marionette.Modals
#		lightbox:
#			selector: '#lightbox'
#
##	Iconto.shared.loader.configure window.ICONTO_MODULES
##
##	# ------------- workspace -------------
##	Iconto.commands.setHandler 'workspace:update', (ViewClass, options, updateOptions) ->
##		App.workspace.showOrUpdate ViewClass, options, updateOptions
##
##	Iconto.commands.setHandler 'workspace:show', (view) ->
##		App.workspace.show view
##
##	Iconto.commands.setHandler 'workspace:fullscreen:enable', (view) ->
##		if App.workspace.hasView()
##			App.workspace.currentView.$el.addClass 'fullscreen'
##
##	Iconto.commands.setHandler 'workspace:fullscreen:disable', (view) ->
##		if App.workspace.hasView()
##			App.workspace.currentView.$el.removeClass 'fullscreen'
##
##	Iconto.commands.setHandler 'workspace:unauthorised', ->
##		App.workspace.$el.addClass 'unauthorised'
##		$('body').addClass 'unauthorised'
##
##	Iconto.commands.setHandler 'workspace:authorised', ->
##		App.workspace.$el.removeClass 'unauthorised'
##		$('body').removeClass 'unauthorised'
##
##	Iconto.commands.setHandler 'workspace:setCustomCompanyStyles', (company) ->
##		console.warn company
##		$('#workspace').addClass "iconto-company-#{company}"
##
##
##	Iconto.commands.setHandler 'workspace:clearDefaultCompanyStyles', ->
##		$('#workspace').removeClass (index, css) ->
##			return '' if !css or !css.match
##			res = css.match(/(^|\s)iconto-company-\S+/g) || []
##			return '' if !res or !res.length
##			return res.join(' ')
##
##	# --------------- modals ---------------
##	Iconto.commands.setHandler 'modals:show', (view) ->
##		App.modals.show view
##
##	Iconto.commands.setHandler 'modals:close', (view) ->
##		App.modals.destroy view
##
##	Iconto.commands.setHandler 'modals:auth:show', (options = {}) ->
##		defaultOptions =
##			title: "Пожалуйста, авторизуйтесь"
##			message: "Данное действие доступно только авторизованным пользователям"
##		#			cancelButtonText: ''
##		#			submitButtonText: ''
##			confirmTitle: 'Авторизация'
##			confirmMessage: 'Вы будете перенаправлены на страницу регистрации'
##			confirmSubmitButtonText: 'Перейти'
##			confirmCancelButtonText: 'Вернуться'
##			checkPreviousAuthorisedUser: true
##			confirmOnClose: true
##			showRegistrationLink: true
##		#			successCallback: @openChat
##		#			errorCallback: ''
##
##		promptOptions = _.extend defaultOptions, options
##		Iconto.shared.views.modals.PromptAuth.show promptOptions
##
##	Iconto.commands.setHandler 'modals:auth:close', (company) ->
##		Iconto.shared.views.modals.PromptAuth.close()
##
##	Iconto.commands.setHandler 'modals:closeAll', ->
##		App.modals.destroyAll()
##
##	# --------------- lightbox ---------------
##	Iconto.commands.setHandler 'lightbox:show', (options) ->
##		lbx = new Iconto.shared.views.modals.LightBox options
##		App.lightbox.show(lbx)
##
##	Iconto.commands.setHandler 'lightbox:close', ->
##		App.lightbox.reset()
##
##	# --------------- errors---------------
##	Iconto.commands.setHandler 'error:global', (error) ->
##		Iconto.shared.views.modals.ErrorAlert.show error
##
##	Iconto.commands.setHandler 'error:notfound', (error) ->
##		Iconto.shared.router.navigate 'notfound', trigger: true
##
##	Iconto.commands.setHandler 'error:websocket:disconnected', (error) =>
##		return false if @errorWebsocketDisconnectedLock
##		@errorWebsocketDisconnectedLock = true
##		Iconto.shared.views.modals.ErrorAlert.show
##			status: error.status
##			msg: 'Проверьте соединение с интернетом'
##			onCancel: ->
##				@errorWebsocketDisconnectedLock = false
##
##	Iconto.commands.setHandler 'error:user:unauthorised', (error, options = {}) ->
##		console.log 'error:user:unauthorised'
##		return false if Iconto.api.userUnauthorisedLock
##		Iconto.api.userUnauthorisedLock = true
##
##		defaultSuccessCallback = ->
##			# Backbone.history.loadUrl(Backbone.history.fragment) # reloading page data without page reload
##			Iconto.api.userUnauthorisedLock = false
##
##		defaultErrorCallback = ->
##			Iconto.api.userUnauthorisedLock = false
##			Iconto.api.logout()
##			.then =>
##				console.log 'defaultErrorCallback'
##				Iconto.shared.router.action "/auth/#{options.queryString}"
##
##		options.queryString ||= "?action=#{window.location.pathname}"
##		options.successCallback ||= defaultSuccessCallback
##		options.errorCallback ||= defaultErrorCallback
##
##		if !!Iconto.api.userId and !!Iconto.api.lastAuthorizedUserId
##			console.log 'all ok'
##			Iconto.shared.views.modals.PromptAuth.show()
##
##		else if !Iconto.api.userId and !!Iconto.api.lastAuthorizedUserId
##			Iconto.shared.views.modals.PromptAuth.show preset: 'sessionExpired'
##
##		else if !Iconto.api.userId and !Iconto.api.lastAuthorizedUserId
##			#			options.queryString += "&user_id=#{Iconto.api.userId}"
##			Iconto.shared.views.modals.PromptAuth.show preset: 'unauthorized'
##
##	lostConnectionHander = ->
##		Iconto.events.once 'internetConnection:found', ->
##			Iconto.ws.reconnect()
##			.done ->
##				Iconto.events.once 'internetConnection:lost', lostConnectionHander
##	Iconto.events.once 'internetConnection:lost', lostConnectionHander
##
##	Iconto.shoppingCartCollection = new Backbone.Collection()
##	Iconto.Cart = {} # revrite cart storage to this
##
##	Iconto.defaultAuthorisedRoute = '/wallet/money'
##	Iconto.defaultUnauthorisedRoute = '/'

	Backbone.history.start
		pushState: true

App.getGoogleMap = (callback) =>
	googleMapsUrl = "https://maps.googleapis.com/maps/api/js?v=3.exp"
	googleMaps = _.get window, "google.maps"

	new Promise (resolve, reject) =>
		if googleMaps
			resolve googleMaps
		else
			$.getScript googleMapsUrl
			.success (res) =>
				resolve _.get window, "google.maps"
			.error (err) =>
				reject err


$ =>
	console.info 'DOM: ready'
	FastClick.attach(document.body)
	console.info 'APPLICATION: starting'
	App.start()
	$(document).foundation()
	console.info 'APPLICATION: started'