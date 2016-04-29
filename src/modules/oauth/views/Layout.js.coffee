@Iconto.module 'oauth.views', (Views) ->
	class Views.Layout extends Marionette.LayoutView
		className: 'layout-view'
		template: JST['oauth/templates/layout']

		regions:
			mainRegion: '.main-region'

		initialize: =>
			@model = new Backbone.Model @options

		onRender: =>
			authView = new Views.AuthView()
			@listenTo authView, 'user:authorized', =>
				Iconto.api.auth()
				.then (user) =>
					if @mainRegion
						@mainRegion.show new Views.ConfirmView(user: user)
					else
						console.error 'mainRegion is not defined'
				.catch (error) =>
					console.error error
				.done()

			Iconto.api.auth()
			.then (user) =>
				@mainRegion.show new Views.ConfirmView(user: user)
			.catch (error) =>
				console.error error
				@mainRegion.show authView
			.done()

			window.INSALES_SUCCESS = false

			window.onbeforeunload = =>
				if window.location.hostname.indexOf('insales') is -1 and window.opener
					message = if window.INSALES_SUCCESS then 'window:close:success' else 'window:close:failure'
					window.opener.postMessage(message, '*')