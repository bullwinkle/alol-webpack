@Iconto.module 'office', (Office) ->
	class Office.Router extends Iconto.shared.UserProfileRouter
		namespace: 'office'

		userProfileRoute: 'office/profile/edit'

		appRoutes:
			'terms(/)': 'terms'
			'agreement(/)': 'agreement'

		#about
			'about(/)': 'about'

		#profile
			'profile(/)': 'profile'
			'profile/edit(/)': 'profileEdit'
			'profile/blacklist(/)': 'profileBlacklist'
			'profile/mastercards(/)': 'profileMastercards'
			'profile/password(/)': 'profilePassword'

			'new(/)': 'newCompany'
			'new/legal(/)': 'newLegal'

		#payment
			'payment(/)': 'payment'
			'payment(/)?order_id=:orderId': 'payment'

	class Office.HelperRouter extends Office.Router
		appRoutes:
			'(/)': 'index'
			'*other': 'pageNotFound'