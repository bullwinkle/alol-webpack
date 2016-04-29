@Iconto.module 'pageNotFound', (pageNotFound) ->

	pageNotFound.router = new pageNotFound.Router controller: new pageNotFound.Controller()