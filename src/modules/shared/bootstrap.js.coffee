@Iconto.module 'shared', (Shared) ->
	Shared.loader = new Shared.Loader()
	Shared.router = new Shared.SharedPublicRouter
		controller: new Shared.SharedController()


	#backward compatibility
	Iconto.mary = Shared.mary = new Shared.services.Mary
	Iconto.ws = Shared.ws = new Shared.services.WebSocket()
	Iconto.intercom = Shared.intercom = new Shared.services.Intercom()
	Iconto.notificator = Shared.notificator = new Shared.services.Notification()