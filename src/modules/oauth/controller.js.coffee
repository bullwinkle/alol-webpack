@Iconto.module 'oauth', (Oauth) ->
	class Oauth.Controller extends Marionette.Controller

		#/oauth
		index: ->
			Iconto.commands.execute 'workspace:show', (new Iconto.oauth.views.Layout())