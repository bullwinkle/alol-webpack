@Iconto.module 'office', (Office) ->
	class Office.CompanyRouter extends Iconto.shared.UserProfileRouter
		namespace: 'office/:companyId'

		userProfileRoute: 'office/profile/edit'

		appRoutes:
			'profile(/)': 'profile'
			'spots(/)': 'spots'
			'branding(/)': 'branding'
			'documents(/)': 'documents'

			'main(/)': 'main'
			'legal(/)': 'legal'
			'addresses(/)': 'addresses'
			'employees(/)': 'employees'
			'employees/new(/)': 'employeesNew'
			'address/:addressId(/)': 'address' # TODO: remove
			'addresses/:addressId(/)': 'address'

		#messages
			'messages(/)': 'messages'

			'messages/chats(/)': 'messagesChats'
			'messages/chat/new(/)': 'messagesChatNew'
			'messages/chat/:chatId(/)': 'messagesChat'

			'messages/deliveries(/)': 'messagesDeliveries'
			'messages/delivery/new(/)': 'messagesDeliveryNew'
			'messages/delivery/:deliveryId(/)': 'messagesDelivery'

			'messages/reviews': 'messagesReviews'

			'messages/settings(/)': 'messagesSettings'

		#customers
			'customers(/)': 'customers'
			'customers/upload(/)': 'customersUpload'

			'customer/new(/)': 'customerNew'
			'customer/:customerId/edit(/)': 'customerEdit'

		#money
			'money(/)': 'money'
			'money/bill(/)': 'moneyBill'
			'money/commit(/)': 'moneyCommit'

		# shop
			'shop(/)': 'shopGoods'
			'shop/orders(/)': 'shopOrders'
			'shop/orders/edit(/)': 'shopOrdersEdit'
			'shop/edit(/)': 'shopEditGoods'
			'shop/edit/categories(/)': 'shopEditCategories'

		# offers
			'offers(/)': 'offers'

		# 'offers/coupons(/)': 'offersCoupons'
		# 'offers/coupon/new(/)': 'offersCouponNew'
		# 'offers/coupon/:couponId/edit(/)': 'offersCouponEdit'
		# 'offers/coupon/:couponId(/)': 'offersCoupon'

		# 'offers/advertisements(/)': 'offersAdvertisements'
		# 'offers/advertisement/new(/)': 'offersAdvertisementNew'
		# 'offers/advertisement/:couponId/edit(/)': 'offersAdvertisementEdit'
		# 'offers/advertisement/:couponId(/)': 'offersAdvertisement'

			'offers/cashbacks': 'offersCashbacks'
		# 'offers/cashbacks/personal': 'offersCashbacksPersonal'
			'offers/cashback/new': 'offersCashbackNew'
			'offers/cashback/:cashbackId': 'offersCashbackEdit'

			'offers/promotions': 'offersPromotions'
			'offers/promotion/new': 'offersPromotionNew'
			'offers/promotion/:promotionId': 'offersPromotionEdit'

			'analytics(/)': 'analytics'
			'analytics/operations': 'analyticsOperations'
			'analytics/payment-return': 'analyticsReturnPayment'

			'add-transaction': 'addTransaction'

		#payment
			'payment(/)': 'payment'
			'payment(/)?order_id=:orderId': 'payment'

		#settings
			'settings/messages(/)': 'settingMessages'
			'settings/messages/faq-question(/:id)': 'faqQuestion'
			'settings/messages/faq-theme(/:id)': 'faqTheme'

		route: (route, name, callback) =>
			super route, name, =>
				Iconto.shared.router.checkedOffer ||= {}
				Iconto.shared.router.checkedOffer.companyIds ||= []

				routeArguments = arguments
				companyId = arguments[0] -= 0
				return callback.apply(@, routeArguments) if Iconto.shared.router.checkedOffer.companyIds.indexOf(companyId) > -1

				company = new Iconto.REST.Company(id: "#{companyId}")

				# check company if company accepted offer, of not - show accept-offer popap
				offerPromise = (new Iconto.REST.Offer()).fetch {type: Iconto.REST.Offer.TYPE_MERCHANT, filters: ['last']}, {reload: true}
				companyPromise = company.fetch()

				Q.all([offerPromise, companyPromise])
				.then ([ offerAttrs, companyAttrs ]) =>
					companyAttrs.accept_offer = !!companyAttrs.accept_offer
					companyAttrs.offer_num -= 0
					offerText = offerAttrs.offer_text
					currentOfferVersion = offerAttrs.id

					isOfferVersionsMatch = if companyAttrs.accept_offer and companyAttrs.offer_num and companyAttrs.offer_num is currentOfferVersion then true else false

					if isOfferVersionsMatch
						Iconto.shared.router.checkedOffer.companyIds.push companyId
						callback.apply(@, routeArguments)
					else
						@action "/auth/offer/merchant/#{companyId}"

				.catch (error) =>
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()


	class Office.CompanyHelperRouter extends Office.CompanyRouter
		appRoutes:
			'(/)': 'index'
			"*other": 'pageNotFound'