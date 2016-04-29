@Iconto.module 'shared', (Shared) ->
	class Shared.BaseRouter extends Marionette.AppRouter
		isRoot: true

		#private static
		history = []

		initialize: =>
			currentPath = window.location.pathname + window.location.search + window.location.hash
			if @getHistory(0) isnt currentPath
				history.push currentPath

		getHistory: (i) =>
			h = _.clone history
			if _.isNumber i
				return h[h.length+i-1]
			return h

		navigate: (path, options) =>
			if _.isNumber path then path = @getHistory path
			history.push path
			if history.length > 10 then history.shift()

			@isRoot = false
			console.info "NAVIGATION:", arguments
			super

		###
			NOTE: DO NOT USE CONCURRENTLY!
			Still, you can chain 'action' calls - they are simply stacked
		###

		#private static
		actions = []

		action: (route, completeRoute = document.location.pathname + document.location.search, routeOptions = {trigger: true}) =>
			actions.push route: route, completeRoute: completeRoute
			@navigate route, routeOptions
			undefined

		complete: (fallbackRoute=Iconto.defaultAuthorisedRoute, options) =>
			options ||= {}
			options.trigger = true if _.isUndefined options.trigger
			options.replace = false if _.isUndefined options.replace
			action = actions.pop()
			if action and
			action.completeRoute isnt Backbone.history.fragment and
			action.completeRoute isnt '/'+Backbone.history.fragment
				route = action.completeRoute
			else if fallbackRoute
				route = fallbackRoute
			else
				route = '/'
			@navigate route, options

		navigateBack: (defaultRoute, options) =>
			if @isRoot
				if defaultRoute
					options ||= {}
					options.trigger = true if options.trigger is undefined
					@navigate defaultRoute, options
				else
					throw 'No route specified for going back'
			else
				window.history.back()

		clearActions: => actions = []

	class Shared.NamespacedRouter extends Shared.BaseRouter
		namespace: ''

		namespacify: (route, namespace) ->
			if route is '(/)' or route is '/'
				route = '/' if route is ''
				route = namespace + route if namespace
				route
			else
				route = namespace + '/' + route if namespace
				route

		route: (route, name, callback) =>
			super @namespacify(route, Marionette.getOption(@, 'namespace')), name, callback

		onRoute: (name, route, params) =>
			route = @namespacify(route, Marionette.getOption(@, 'namespace'))
			console.info 'ROUTE:', route, params, "HANDLER:", name

	namespacedRouter = new Shared.NamespacedRouter()

	class Shared.AuthenticatedRouter extends Shared.NamespacedRouter

		defaultUnauthorizedRoute: '/auth'

		#override default route method to check if user is authorized
		route: (route, name, callback) => #TODO: replace with overriding 'execute' method http://backbonejs.org/#Router
			super route, name, =>
				routeArguments = Array::slice.call arguments

				Iconto.api.auth()
				.then (userAttrs) =>
					callback.apply @, routeArguments
				.catch (error) =>
					console.error error
					publicRoute = _.isArray(@publicRoutes) and route in @publicRoutes
					if publicRoute
						console.info 'Public route', route
						return callback.apply namespacedRouter, routeArguments
					if (Iconto.api.lastAuthorizedUserId)
						return Iconto.commands.execute 'error:user:unauthorised'
#						return Iconto.commands.execute 'modals:auth:show'

					@action 'auth'

				.done()

	class Shared.UserProfileRouter extends Shared.AuthenticatedRouter
		userProfileRoute: ''

		route: (route, name, callback) =>
			super route, name, =>
				routeArguments = Array::slice.call arguments
				Iconto.api.auth()
				.then (user) =>
					# (user.is_real == true) - only fake merchants, (user.is_real == false) - others
					# empty field == null
					if !user.is_real and (!user.first_name or !user.last_name or !user.email)
						unless Backbone.history.fragment is @userProfileRoute
							@action "/auth/profile", null, trigger: true, replace: true
						else
							callback.apply @, routeArguments
					else
						callback.apply @, routeArguments
				.catch (error) =>
					console.error error
					return callback.apply namespacedRouter, routeArguments
				.done()

	class Shared.SharedPublicRouter extends Shared.NamespacedRouter
		namespace: 'shared'

		appRoutes:
			'order-form(/)(?*formPath)': 'orderForm'

			'*other': 'pageNotFound'