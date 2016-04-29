@Iconto.module 'icgy', (Icgy) ->

	class Icgy.Controller extends Marionette.Controller

		#/icgy
		index: ->
			Iconto.commands.execute 'workspace:show', (new Iconto.icgy.views.ShortLinkGeneratorView())