@Iconto.module 'wallet', (Wallet) ->
	updateWorkspace = (params, updateOptions) ->
		Iconto.commands.execute 'workspace:update', Wallet.views.Layout, params, updateOptions

	updateRightWorkspace = (params) ->
		_.set(params, 'updateOptions', {
			position: 'right'
		})
		Iconto.commands.execute 'workspace:update', Wallet.views.Layout, params

	updateRight2Workspace = (params) ->
		_.set(params, 'updateOptions', {
			position: 'right2'
		})
		Iconto.commands.execute 'workspace:update', Wallet.views.Layout, params

	updateLeftWorkspace = (params) ->
		_.set(params, 'updateOptions', {
			position: 'left'
		#			clearState: false
		})
		Iconto.commands.execute 'workspace:update', Wallet.views.Layout, params

	parseQueryParams = (queryParamsString="") ->
		return false unless queryParamsString
		if queryParamsString[0] isnt '?'
			queryParamsString = "?#{queryParamsString}"
		# Iconto.shared.helpers.navigation.getQueryParams queryParamsString
		queryParamsString

	class Wallet.Controller extends Marionette.Controller

		#/
		index: ->
			Wallet.router.navigate Iconto.defaultAuthorisedRoute, trigger: true, replace: true

		#/other
		pageNotFound: ->
			updateWorkspace
				page: 'pageNotFound'

		#about
		#/wallet/about
		about: =>
			updateWorkspace
				page: 'about'

		#terms
		#/wallet/terms
		terms: =>
			updateWorkspace
				page: 'terms'
				subpage: 'wallet'

		#/wallet/tariffs
		tariffs: =>
			updateWorkspace
				page: 'tariffs'
				subpage: 'wallet'
		#money
		#/wallet/money
		money: ->
			Wallet.router.navigate 'wallet/cards', trigger: true, replace: true

		#/wallet/money/cashback
		moneyCashback: ->
			updateWorkspace
				page: 'money'
				subpage: 'cashback'

		#/wallet/money/cashback/:cashbackId/transaction(/)
		moneyTransaction: (cashbackId) ->
			cashbackId -= 0
			updateWorkspace
				page: 'money'
				subpage: 'transaction'
				cashbackId: cashbackId

		#/wallet/money/cashback/:cashbackId/order(/)
		moneyOrder: (cashbackId) ->
			cashbackId -= 0
			updateWorkspace
				page: 'money'
				subpage: 'order'
				cashbackId: cashbackId

		#/wallet/money/card/:cardId/cashback/:cashbackId/transaction(/)
		moneyCardTransaction: (cardId, cashbackId) ->
			cardId -= 0
			cashbackId -= 0
			updateWorkspace
				page: 'money'
				subpage: 'transaction'
				cashbackId: cashbackId
				cardId: cardId

		#/wallet/money/card/:cardId/cashback/:cashbackId/order(/)
		moneyCardOrder: (cardId, cashbackId) ->
			cashbackId -= 0
			cardId -= 0
			updateWorkspace
				page: 'money'
				subpage: 'order'
				cashbackId: cashbackId
				cardId: cardId

		#/wallet/cards
		cards: ->
			updateWorkspace
				page: 'money'
				subpage: 'cards'

		#/wallet/cards/mastercard
		mastercard: ->
			updateWorkspace
				page: 'money'
				subpage: 'mastercard'

		#/wallet/cards/mastercard/get
		mastercardGet: ->
			updateWorkspace
				page: 'money'
				subpage: 'mastercardGet'

		#/wallet/money/withdraw
		moneyWithdraw: ->
			updateWorkspace
				page: 'money'
				subpage: 'withdraw'

		#/wallet/money/payment
		moneyPayment: ->
			updateWorkspace
				page: 'money'
				subpage: 'payment'

		#/wallet/money/card/new
		moneyCardNew: ->
			updateWorkspace
				page: 'money'
				subpage: 'new-card'

		#/wallet/money/card/:cardId(/)
		moneyCard: (cardId) ->
			cardId -= 0
			updateWorkspace
				page: 'money'
				subpage: 'card'
				cardId: cardId

		#/wallet/money/card/:cardId/transaction/transactionId(/)
		transactionInfo: (cardId, transactionId) ->
			cardId -= 0
			updateWorkspace
				page: 'money'
				subpage: 'transaction'
				cardId: cardId
				transactionId: transactionId

		#/wallet/money/card/:cardId/charge
		moneyCardCharge: (cardId) ->
			cardId - 0
			updateWorkspace
				page: 'money'
				subpage: 'charge'
				cardId: cardId

		moneyCardSettings: (cardId) ->
			cardId - 0
			updateWorkspace
				page: 'money'
				subpage: 'settings'
				cardId: cardId
		#/wallet/messages
		messages: ->
			Wallet.router.navigate "wallet/messages/chats", trigger: true, replace: true

		#/wallet/messages/chats
		messagesChats: ->
			updateWorkspace
				page: 'messages'
				subpage: 'chats'

		#/wallet/messages/chat/new/qr
		messagesChatNewQr: ->
			updateWorkspace
				page: 'messages'
				subpage: 'new-chat-qr'

		#/wallet/messages/chat/new
		messagesChatNew: ->
			updateWorkspace
				page: 'messages'
				subpage: 'new-chat'

		#/wallet/messages/chat/:chatId
		messagesChat: (chatId) ->
			# updateRightWorkspace # commented because of unread state
			# updateWorkspace # do not reload page but update state
			updateWorkspace
				page: 'messages'
				subpage: 'chat'
				chatId: chatId,
				{forceShow: true}

		#/wallet/messages/chat/:chatId/info
		messagesChatInfo: (chatId) ->
			updateWorkspace
				page: 'messages'
				subpage: 'chat-info'
				chatId: chatId

		#/wallet/messages/settings
		messagesSettings: ->
			updateWorkspace
				page: 'messages'
				subpage: 'settings'

		#profile
		#/wallet/profile
		profile: ->
			updateWorkspace
				page: 'user-profile'

		#/wallet/profile/edit
		profileEdit: ->
			updateWorkspace
				page: 'user-profile'
				subpage: 'edit'

		#/wallet/profile/blacklist
		profileBlacklist: ->
			updateWorkspace
				page: 'user-profile'
				subpage: 'blacklist'

		#/wallet/profile/mastercards
		profileMastercards: ->
			updateWorkspace
				page: 'user-profile'
				subpage: 'mastercards'

		#/wallet/profile/clientcode
		profileClientcode: ->
			updateWorkspace
				page: 'user-profile'
				subpage: 'clientcode'

		#/wallet/profile/password
		profilePassword: ->
			updateWorkspace
				page: 'user-profile'
				subpage: 'password'

		#/wallet/profile/verification
		verification: ->
			updateWorkspace
				page: 'verification'

		#/wallet/profile/verification/confirmation
		verificationConfirmation: ->
			updateWorkspace
				page: 'verification'
				subpage: 'confirmation'

		#/wallet/profile/verification/status
		verificationStatus: ->
			updateWorkspace
				page: 'verification'
				subpage: 'status'

		#offers
		#/wallet/offers
		offers: ->
			Wallet.router.navigate "/wallet/offers/feed", trigger: true, replace: true

		#/wallet/offers/feed
		offersFeed: ->
			updateWorkspace
				page: 'offers'
				subpage: 'feed'


		#/wallet/offers/favourites
		offersFavourites: ->
			updateWorkspace
				page: 'offers'
				subpage: 'favourites'

		#/wallet/offers/cashbacks/:conpanyId
		offersFeedCashbacksGroup: (companyId) ->
			updateWorkspace
				page: 'offers'
				subpage: 'company-cashbacks'
				companyId: companyId

		#/wallet/offers/cashbacks/:conpanyId/:offerItemId
		offersFeedCashbackInGroup: (companyId, cashbackId) ->
			updateRightWorkspace
				page: 'offer'
				objectType: 'cashback'
				offerItemId: cashbackId
				companyId: companyId
				cashbackInGroup: true
				from: 'feed-cashback-group'

		#/wallet/offer/:objectType/:offerItemId(/)
		offerItemDetails: (objectType, offerItemId) ->
			updateRightWorkspace
				page: 'offer'
				objectType: objectType
				offerItemId: offerItemId
				from: 'feed'

		#/wallet/payment(/)
		#/wallet/payment(/)?order_id=:orderId
		payment: (orderId) =>
			orderId = Iconto.shared.helpers.navigation.getQueryParams()['order_id'] - 0 || 0;
			if orderId
				order = new Iconto.REST.Order id: orderId
				order.fetch()
				.then (order) =>
					Iconto.shared.loader.load('payment')
					.then =>
						updateWorkspace
							page: 'payment'
							orderId: orderId
							order: order
				.catch (error) =>
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()

		#/wallet/company/:companyId/:action(/)
		company: (companyId) ->
			companyId -= 0
			updateWorkspace
				page: 'company'
				companyId: companyId
				action: Backbone.history.fragment.split('/')[3] or 'offers'

		#/wallet/company/:companyId/offers
		companyOffers: (companyId) ->
			companyId -= 0
			updateWorkspace
				page: 'company'
				subpage: 'offers'
				companyId: companyId

		#/wallet/company/:companyId/offers/:objectType/:offerItemId(/)
		companyOfferDetails: (companyId, objectType, offerItemId) ->
			companyId -= 0
			objectType += ''
			offerItemId -= 0
			updateRightWorkspace
				page: 'company-offer'
				objectType: objectType
				companyId: companyId
				offerItemId: offerItemId
				from: 'company'

		#/wallet/company/:companyId/chat-straightway(/)
		companyAddressSelectToChatWith: (companyId) ->
			companyId -= 0
			updateWorkspace
				page: 'company'
				companyId: companyId
				chatStraightway: true

		companyAddresses: (companyId) ->
#			updateRightWorkspace
			updateWorkspace
				page: 'company'
				subpage: 'addresses'
				companyId: +companyId

		#/wallet/company/:companyId/address/:addressId(/)
		companyAddressDetails: (companyId, addressId) ->
			companyId -= 0
			addressId -= 0
#			updateRight2Workspace
			updateRightWorkspace
				page: 'company'
				subpage: 'address'
				companyId: companyId
				addressId: addressId


		#company/:companyId/address/:addressId/offers/feed(/)
		companyOffersFeed: (companyId, addressId) ->
			companyId -= 0
			addressId -= 0
			updateWorkspace
				page: 'company-offers'
				subpage: 'offers'
				companyId: companyId
				addressId: addressId

		#company/:companyId/address/:addressId/offer/:objectType/:offerItemId(/)
		companyOfferItemDetails: (companyId, addressId, objectType, offerItemId) ->
			companyId -= 0
			addressId -= 0
			objectType += ''
			offerItemId -= 0
			updateWorkspace
				page: 'company-offer'
				objectType: objectType
				companyId: companyId
				addressId: addressId
				offerItemId: offerItemId

		test: ->
			updateWorkspace
				page: 'test'

		crop: ->
			updateWorkspace
				page: 'crop'

		registrator: ->
			updateWorkspace
				page: 'registrator'

		shop: (companyId, addressId, queryParams) ->
			updateWorkspace
				page: 'shop'
				company_id: +companyId
				address_id: +addressId
				queryParams: parseQueryParams queryParams

		shopCart: (companyId, addressId, queryParams) ->
			updateWorkspace
				page: 'shop'
				subpage: 'cart'
				company_id: +companyId
				address_id: +addressId
				queryParams: parseQueryParams queryParams

		shopCategory: (companyId, addressId, categoryId, queryParams) ->
			updateWorkspace
				page: 'shop'
				subpage: 'category'
				company_id: +companyId
				address_id: +addressId
				category_id: +categoryId
				queryParams: parseQueryParams queryParams

		shopProduct: (companyId, addressId, categoryId, productId, queryParams) ->
			updateWorkspace
				page: 'shop'
				subpage: 'product'
				company_id: +companyId
				address_id: +addressId
				category_id: +categoryId
				product_id: +productId
				queryParams: parseQueryParams queryParams

		services: ->
			updateWorkspace
				page: 'services'

		taxiService: ->
			updateWorkspace
				page: 'services'
				subpage: 'taxi'
