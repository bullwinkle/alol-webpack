@Iconto.module 'oauth', (Oauth) ->
	Oauth.router = new Oauth.Router controller: new Oauth.Controller()