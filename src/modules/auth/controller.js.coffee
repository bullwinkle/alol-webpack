@Iconto.module 'auth', (Auth) ->
	class Auth.Controller extends Marionette.Controller

		# PRIVATE
		fromPublicRoute = false
		lastAuthorizedUserId = Iconto.api.lastAuthorizedUserId
		
		showAuthorized = (View, options = {}) ->
			currentUserId = _.get(Iconto, 'api.userId')
			currentUser = _.get(Iconto, "REST.cache.user[#{currentUserId}]")
			if currentUser
				options.user = currentUser
				Iconto.commands.execute 'workspace:show', new View options
			else
				Iconto.api.auth()
				.then (user) ->
					options.user = user
					Iconto.commands.execute 'workspace:show', new View options
				.catch (error) ->
					console.error error
					Auth.router.navigate '/auth', trigger: true, replace: true
				.done()
				
		showAll = (View, options = {}) ->
			Iconto.commands.execute 'workspace:show', new View options


		# PUBLIC
		
		# /auth(/)
		authIndex: =>
			routeOptions = 	trigger: true, replace: true

			Iconto.api.auth()
			.then (user) ->
				Auth.router.navigate '/', routeOptions
			.catch (error) ->
				console.error error
				query = Iconto.shared.helpers.navigation.getQueryParams()
				if query.user_id then lastAuthorizedUserId = query.user_id
				if query.fromPublicRoute then fromPublicRoute = query.fromPublicRoute
				if query.action
					Auth.router.action '/auth/signup', query.action, routeOptions
				else
					Auth.router.navigate '/auth/signup', routeOptions

			.done()

		authSignin: =>
			options = page: 'signin'
			if lastAuthorizedUserId then options.lastAuthorizedUserId = lastAuthorizedUserId
			if fromPublicRoute
				options.fromPublicRoute = fromPublicRoute
				fromPublicRoute = false
			showAll Iconto.auth.views.AuthView, options

		authSignup: =>
			options = page: 'signup'
			showAll Iconto.auth.views.AuthView, options

		authRestore: =>
			options = page: 'restore'
			showAll Iconto.auth.views.AuthView, options

		# /auth/profile(/)
		profileIndex: =>
			showAuthorized Iconto.auth.views.userProfile.ProfileView

		profileEdit: =>
			showAuthorized Iconto.auth.views.userProfile.ProfileEditView

		profileBlacklist: =>
			showAuthorized Iconto.auth.views.userProfile.BlacklistView
				
		profilePassword: =>
			showAuthorized Iconto.auth.views.userProfile.PasswordView
				
		# /auth/offer(/)
		offerIndex: =>
			showAuthorized Iconto.auth.views.offer.OfferUserView

		offerUser: =>
			showAuthorized Iconto.auth.views.offer.OfferUserView

		offerMerchant: (merchantId) =>
			showAuthorized Iconto.auth.views.offer.OfferMerchantView,
				merchantId: merchantId
				
		pageNotFound: =>
			showAll Iconto.shared.views.PageNotFound