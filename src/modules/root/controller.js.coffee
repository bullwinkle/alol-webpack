@Iconto.module 'root', (Root) ->
	class Root.Controller extends Marionette.Controller

		show = (view) ->
			Iconto.commands.execute 'workspace:show', view

		#(/)
		indexRoute: ->
			###
				if user authorised - navigate to [ authorisedRoute ]
				if NOT
					if user want to open specific app (branding or wrt) - open spicific app view
					ELSE - navigate to [ unAuthorisedRoute ]
			###
			authorisedRoute = Iconto.defaultAuthorisedRoute
			unAuthorisedRoute = '/auth/signup'

			Iconto.api.auth()
			.then (user) => #authorized
#				route = if window.ICONTO_APPLICATION is 'wrt.to' then 'wallet/messages/chats' else 'wallet/money
				Root.router.navigate authorisedRoute, trigger: true, replace: true
			.catch (error) => #unauthorized
				console.error error
				if error.status is 200005

					if window.ICONTO_APPLICATION_DOMAIN and window.ICONTO_APPLICATION_DOMAIN_SETTINGS
						# branding landing, e.g. anypasta.iconto.net
						show new Iconto.root.views.branding.Layout()
						console.log 'BRANDING АЛОЛЬ LANDING'

					else if window.ICONTO_APPLICATION is 'wrt.to'
						if window.ICONTO_APPLICATION_DOMAIN and window.ICONTO_APPLICATION_DOMAIN_SETTINGS
							# branding wrt.to, e.g. anypasta.wrt.to
							console.log 'BRANDING WRT.TO LANDING'
							window.location.href = '//wrt.to'
						# wrt.to landing, e.g. wrt.to
						else
							show new Iconto.root.views.wrt.Layout()
							console.log 'WRT.TO LANDING'

					else
						Iconto.shared.router.navigate unAuthorisedRoute, trigger: true
				else
					Iconto.shared.views.modals.ErrorAlert.show error
			.done()

#		#wrt.to/signup
#		wrtSignup: =>
#			if window.ICONTO_APPLICATION is 'wrt.to'
#				Iconto.commands.execute 'workspace:show', new Root.views.wrt.Signup()
#			else
#				Root.router.navigate "/", trigger: true
#
#		#wrt.to/signin
#		wrtSignin: =>
#			if window.ICONTO_APPLICATION is 'wrt.to'
#				Iconto.commands.execute 'workspace:show', new Root.views.wrt.Signin()
#			else
#				Root.router.navigate "/", trigger: true