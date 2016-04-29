@Iconto.module 'auth', (Auth) ->

	Auth.controller = new Auth.Controller()

	Auth.router = new Auth.Router controller: Auth.controller