@Iconto.module 'wallet', (Wallet) ->

	class Wallet.Router extends Iconto.shared.UserProfileRouter
		namespace: 'wallet'

		userProfileRoute: 'wallet/profile/edit'

		appRoutes:

		#terms
			'terms(/)': 'terms'
			'tariffs(/)': 'tariffs'
		#about
			'about(/)': 'about'

		#cards
			'cards(/)': 'cards'
			'cards/mastercard(/)': 'mastercard'
			'cards/mastercard/get(/)': 'mastercardGet'

		#money
			'money(/)': 'money'
			'money/cashback(/)': 'moneyCashback'
			'money/cashback/:cashbackId/transaction(/)': 'moneyTransaction'
			'money/cashback/:cashbackId/order(/)': 'moneyOrder'
			'money/withdraw(/)': 'moneyWithdraw'
			'money/card/new(/)': 'moneyCardNew'
			'money/card/:cardId(/)': 'moneyCard'
			'money/card/:cardId/cashback/:cashbackId/transaction(/)': 'moneyCardTransaction'
			'money/card/:cardId/cashback/:cashbackId/order(/)': 'moneyCardOrder'
#			'money/card/:cardId/transaction/:transactionId(/)': 'transactionInfo'
			'money/card/:cardId/charge': 'moneyCardCharge'
			'money/card/:cardId/settings': 'moneyCardSettings'
			'money/payment': 'moneyPayment'

		#messages
			'messages(/)': 'messages'
			'messages/chats(/)': 'messagesChats'
			'messages/chat/new/qr(/)': 'messagesChatNewQr'
			'messages/chat/new(/)': 'messagesChatNew'
			'messages/chat/:chatId(/)': 'messagesChat'
			'messages/chat/:chatId/info(/)': 'messagesChatInfo'
			'messages/settings(/)': 'messagesSettings'

		#profile
			'profile(/)': 'profile'
			'profile/edit(/)': 'profileEdit'
			'profile/blacklist(/)': 'profileBlacklist'
			'profile/password(/)': 'profilePassword'
			'profile/mastercards(/)': 'profileMastercards'
			'profile/clientcode(/)': 'profileClientcode'

			'profile/verification(/)': 'verification'
			'profile/verification/confirmation(/)': 'verificationConfirmation'
			'profile/verification/status(/)': 'verificationStatus'

		#offers
			'offers(/)': 'offers'
			'offers/feed(/)': 'offersFeed'
			'offers/favourites(/)': 'offersFavourites'
			'offers/cashbacks/:companyId(/)': 'offersFeedCashbacksGroup'
			'offers/cashbacks/:companyId/:cashbackId': 'offersFeedCashbackInGroup'
			'offers/:objectType/:offerItemId(/)': 'offerItemDetails'

		#payment
			'payment(/)': 'payment'
			'payment(/)?order_id=:orderId': 'payment'

		#company
			'company/:companyId/addresses(/)': 'companyAddresses'
			'company/:companyId/address/:addressId(/)': 'companyAddressDetails'
			'company/:companyId/address/:addressId/offers(/)': 'companyOffersFeed'
			'company/:companyId/address/:addressId/offers/:objectType/:offerItemId(/)': 'companyOfferItemDetails'

			'company/:companyId/chat-straightway(/)': 'companyAddressSelectToChatWith'

#			'company/:companyId/offers(/)': 'companyOffers'

			'company/:companyId(/)': 'company'
			'company/:companyId/info(/)': 'company'
			'company/:companyId/offers(/)': 'companyOffers'
			'company/:companyId/news(/)': 'company'
			'company/:companyId/offers/:objectType/:offerItemId(/)': 'companyOfferDetails'

		#shop
			'company/:companyId/(address/:addressId/)shop(/)': 'shop'
			'company/:companyId/(address/:addressId/)shop/cart': 'shopCart'
			'company/:companyId/(address/:addressId/)shop/category/:categoryId': 'shopCategory'
			'company/:companyId/(address/:addressId/)shop/(category/:categoryId/)product/:productId': 'shopProduct'

		#services
			'services': 'services'
			'services/taxi': 'taxiService'

		#test
			'test': 'test'

		#registrator
#			'registrator(/)': 'registrator'

		#public routes, copy name from above and paste here
		publicRoutes: [
			'company/:companyId(/)'
			'company/:companyId/info(/)'
			'company/:companyId/offers(/)'
			'company/:companyId/news(/)'
			'company/:companyId/offers/:objectType/:offerItemId(/)'
			'company/:companyId/(address/:addressId/)shop(/)'
			'company/:companyId/(address/:addressId/)shop/category/:categoryId'
			'company/:companyId/(address/:addressId/)shop/category/:categoryId/product/:productId'
			'company/:companyId/address/:addressId(/)'
			'company/:companyId/address/:addressId/offers(/)'
			'company/:companyId/address/:addressId/offers/:objectType/:offerItemId(/)'

			'offers/cashbacks/:companyId(/)'
			'offers/cashbacks/:companyId/:cashbackId'
			'offers/:objectType/:offerItemId(/)'

			'services/taxi'
		]

		route: (route, name, callback) =>
			super route, name, =>
				Iconto.shared.router.checkedOffer ||= {}
				Iconto.shared.router.checkedOffer.currentUser ||= false

				routeArguments = Array::slice.call arguments

				if route in @publicRoutes or
				Iconto.shared.router.checkedOffer.currentUser
					return callback.apply(@, routeArguments)

				userPromise = Iconto.api.auth()
				offerPromise = (new Iconto.REST.Offer()).fetch({ type: Iconto.REST.Offer.TYPE_USER, filters: ['last'] }, {reload:true})

				Q.all([userPromise, offerPromise])
				.spread (user, offer) =>
					offerText = offer.offer_text
					currentOfferVersion = offer.id

					isOfferVersionsMatch = !!user.is_offer_accepted and _.get(user, 'offer_version') is currentOfferVersion
					if isOfferVersionsMatch
						Iconto.shared.router.checkedOffer.currentUser = true
						callback.apply(@, routeArguments)
					else
						@action '/auth/offer/user'

				.catch (error) =>
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()

	class Wallet.HelperRouter extends Wallet.Router
		appRoutes:
			'(/)': 'index'
			'*other(/)': 'pageNotFound'