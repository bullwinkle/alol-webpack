@Iconto.module 'auth', (Auth) ->

	class Auth.Router extends Iconto.shared.NamespacedRouter
		namespace: 'auth'

		appRoutes:

		# /auth(/)
			'(/)': 'authIndex'
			'signin(/)': 'authSignin'
			'signup(/)': 'authSignup'
			'restore(/)': 'authRestore'

		# /auth/profile(/)
			'profile(/)': 'profileEdit'
#			'profile/edit(/)': 'profileEdit'
#			'profile/blacklist(/)': 'profileBlacklist'
#			'profile/password(/)': 'profilePassword'

		# /auth/offer(/)
			'offer(/)': 'offerIndex'
			'offer/user(/)': 'offerUser'
			'offer/merchant/:merchantId(/)': 'offerMerchant'
			
		# other
			'*other': 'pageNotFound'
