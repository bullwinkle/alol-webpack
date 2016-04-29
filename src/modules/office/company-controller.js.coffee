@Iconto.module 'office', (Office) ->
	updateWorkspace = (params, updateOptions) ->
		Iconto.commands.execute 'workspace:update', Office.views.Layout, params, updateOptions

	updateRightWorkspace = (params) ->
		_.set(params,'updateOptions', {
			position: 'right'
		})
		Iconto.commands.execute 'workspace:update', Office.views.Layout, params

	class Office.CompanyController extends Marionette.Controller

		# common

		#office/:companyId(/)
		index: (companyId) ->
			unless _.isNaN(companyId)
				Office.router.navigate "office/#{companyId}/messages/chats", trigger: true, replace: true
			else
				@pageNotFound.apply @, arguments

		# profile

		#office/:companyId/profile
		profile: (companyId) ->
			updateWorkspace
				page: 'company-profile'
				companyId: companyId

		#office/:companyId/profile/spots
		spots: (companyId) ->
			updateWorkspace
				page: 'spots'
				companyId: companyId

		branding: (companyId) ->
			updateWorkspace
				page: 'branding'
				companyId: companyId

		documents: (companyId) ->
			updateWorkspace
				page: 'documents'
				companyId: companyId

		main: (companyId) ->
			updateWorkspace
				page: 'edit'
				companyId: +companyId

		#/office/:companyId/employees
		employees: (companyId) ->
			updateWorkspace
				page: 'employees'
				companyId: +companyId

		#/office/:companyId/employees
		employeesNew: (companyId) ->
			updateWorkspace
				page: 'employees'
				subpage: 'new'
				companyId: +companyId

		#/office/:companyId/addresses
		addresses: (companyId) ->
			updateWorkspace
				page: 'addresses'
				companyId: companyId

		#/office/:companyId/address/:addressId
		address: (companyId, addressId) ->
			addressId -= 0
			updateWorkspace
				page: 'address'
				companyId: companyId
				addressId: addressId

		#/office/:companyId/legal/:legalId
		legal: (companyId) ->
			updateWorkspace
				page: 'legal'
				companyId: +companyId

		# messages

		#office/:companyId/messages
		messages: (companyId) =>
			@index(companyId)

		#office/:companyId/messages/chats
		messagesChats: (companyId) =>
			updateWorkspace
				page: 'messages'
				subpage: 'chats'
				companyId: companyId

		#office/:companyId/messages/chat/new
		messagesChatNew: (companyId) =>
			updateWorkspace
				page: 'messages'
				subpage: 'chat'
				companyId: companyId

		#office/:companyId/messages/chat/:chatId
		messagesChat: (companyId, chatId) =>
			updateWorkspace
				page: 'messages'
				subpage: 'chat'
				companyId: companyId
				chatId: chatId,
				{forceShow: true}

		#office/:companyId/messages/deliveries
		messagesDeliveries: (companyId) =>
			updateWorkspace
				page: 'messages'
				subpage: 'deliveries'
				companyId: companyId

		#office/:companyId/messages/delivery/new
		messagesDeliveryNew: (companyId) =>
			updateWorkspace
				page: 'messages'
				subpage: 'new-delivery'
				companyId: companyId

		#office/:companyId/messages/delivery/:deliveryId
		messagesDelivery: (companyId, deliveryId) =>
			deliveryId -= 0
			updateWorkspace
				page: 'messages'
				subpage: 'delivery'
				companyId: companyId
				deliveryId: deliveryId

		messagesReviews:  (companyId) =>
			updateWorkspace
				page: 'messages'
				subpage: 'reviews'
				companyId: +companyId

		#office/:companyId/messages/settings
		messagesSettings: (companyId) =>
			updateWorkspace
				page: 'messages'
				subpage: 'settings'
				companyId: companyId

		# customers

		#office/:companyId/customers
		customers: (companyId) ->
			updateWorkspace
				page: 'customers'
				companyId: companyId

		#office/:companyId/customers/upload
		customersUpload: (companyId) ->
			unless Iconto.shared.helpers.device.isIos()
				updateWorkspace
					page: 'customers'
					subpage: 'upload'
					companyId: companyId
			else
				Iconto.office.companyRouter.navigate "office/#{companyId}/customers", trigger: true, replace: true

		#office/:companyId/customer/new
		customerNew: (companyId) ->
			updateWorkspace
				page: 'customer'
				subpage: 'new'
				companyId: companyId

		#office/:companyId/customer/:customerId/edit
		customerEdit: (companyId, customerId) ->
			customerId -= 0
			updateWorkspace
				page: 'customer'
				subpage: 'edit'
				companyId: companyId
				customerId: customerId
				{forceShow:true}

		# money

		#office/:companyId:/money
		money: (companyId) ->
			updateWorkspace
				page: 'money'
				companyId: companyId

		#office/:companyId/money/bill
		moneyBill: (companyId) ->
			updateWorkspace
				page: 'money'
				subpage: 'bill'
				companyId: companyId

		#office/:companyId/money/commit
		moneyCommit: (companyId) ->
			updateWorkspace
				page: 'money'
				subpage: 'commit'
				companyId: companyId

		# shop

		#office/:companyId/shop(/)
		shopGoods: (companyId) ->
			updateWorkspace
				page: 'shop'
				subpage: 'goods'
				companyId: +companyId

		#office/:companyId/shop/orders(/)
		shopOrders: (companyId) ->
			updateWorkspace
				page: 'shop'
				subpage: 'orders'
				companyId: +companyId

		#office/:companyId/shop/orders/edit(/)
		shopOrdersEdit: (companyId) ->
			updateWorkspace
				page: 'shop'
				subpage: 'ordersEdit'
				companyId: +companyId

		#office/:companyId/shop/edit(/)
		shopEditGoods: (companyId) ->
			updateWorkspace
				page: 'shop'
				subpage: 'editGoods'
				companyId: +companyId

		#office/:companyId/shop/edit/categories(/)
		shopEditCategories: (companyId) ->
			updateWorkspace
				page: 'shop'
				subpage: 'editCategories'
				companyId: +companyId

		# offers

		#office/:companyId/offers(/)
		offers: (companyId) ->
			# Office.router.navigate "office/#{companyId}/offers/coupons", trigger: true, replace: true
			Office.router.navigate "office/#{companyId}/offers/cashbacks", trigger: true, replace: true

#		#office/:companyId/offers/coupons
#		offersCoupons: (companyId) ->
#			updateWorkspace
#				page: 'offers'
#				subpage: 'coupons'
#				companyId: companyId
#
#		#office/:companyId/offers/coupon/new
#		offersCouponNew: (companyId) ->
#			updateWorkspace
#				page: 'offers'
#				subpage: 'coupon'
#				mode: 'new'
#				companyId: companyId
#
#		#office/:companyId/offers/coupon/:couponId/edit
#		offersCouponEdit: (companyId, couponId) ->
#			couponId -= 0
#			updateWorkspace
#				page: 'offers'
#				subpage: 'coupon'
#				mode: 'edit'
#				companyId: companyId
#				couponId: couponId
#
#		#office/:companyId/offers/coupon/:couponId
#		offersCoupon: (companyId, couponId) ->
#			couponId -= 0
#			updateWorkspace
#				page: 'offers'
#				subpage: 'coupon'
#				mode: 'view'
#				companyId: companyId
#				couponId: couponId
#
#		#office/:companyId/offers/advertisements
#		offersAdvertisements: (companyId) ->
#			updateWorkspace
#				page: 'offers'
#				subpage: 'advertisements'
#				companyId: companyId
#
#		#office/:companyId/offers/advertisement/new
#		offersAdvertisementNew: (companyId) ->
#			updateWorkspace
#				page: 'offers'
#				subpage: 'advertisement'
#				mode: 'new'
#				companyId: companyId
#
#		#office/:companyId/offers/advertisement/:advertisementId/edit
#		offersAdvertisementEdit: (companyId, advertisementId) ->
#			advertisementId -= 0
#			updateWorkspace
#				page: 'offers'
#				subpage: 'advertisement'
#				companyId: companyId
#				mode: 'edit'
#				advertisementId: advertisementId
#
#		#office/:companyId/offers/advertisement/:advertisementId
#		offersAdvertisement: (companyId, advertisementId) ->
#			advertisementId -= 0
#			updateWorkspace
#				page: 'offers'
#				subpage: 'advertisement'
#				mode: 'view'
#				companyId: companyId
#				advertisementId: advertisementId

		offersCashbacks: (companyId) ->
			updateWorkspace
				page: 'offers'
				subpage: 'cashbacks'
				companyId: companyId

#		#:companyId/offers/cashbacks/personal
#		offersCashbacksPersonal: (companyId) ->
#			updateWorkspace
#				page: 'offers'
#				subpage: 'cashbacks'
#				mode: 'personal'
#				companyId: companyId

		#:companyId/offers/cashback/new
		offersCashbackNew: (companyId) ->
			updateWorkspace
				page: 'offers'
				subpage: 'cashback'
				companyId: companyId

		#:companyId/offers/cashback/:cashbackId
		offersCashbackEdit: (companyId, cashbackId) ->
			cashbackId -= 0
			updateWorkspace
				page: 'offers'
				subpage: 'cashback'
				companyId: companyId
				cashbackId: cashbackId

		offersPromotions: (companyId) ->
			updateWorkspace
				page: 'offers'
				subpage: 'promotions'
				companyId: companyId

		offersPromotionNew: (companyId) ->
			updateWorkspace
				page: 'offers'
				subpage: 'promotion'
				companyId: companyId

		offersPromotionEdit: (companyId, promotionId) ->
			promotionId -= 0
			updateWorkspace
				page: 'offers'
				subpage: 'promotion'
				companyId: companyId
				promotionId: promotionId

		# analytics

		#office/:companyId/analytics
		analytics: (companyId) ->
			route = "office/#{companyId}/analytics/operations"
			Office.router.navigate route, trigger: true, replace: true


		#office/:companyId/analytics/operations
		analyticsOperations: (companyId) ->
			updateWorkspace
				page: 'analytics'
				subpage: 'operations'
				companyId: companyId

		#office/:companyId/analytics/payment-return
		analyticsReturnPayment: (companyId) ->
			updateWorkspace
				page: 'analytics'
				subpage: 'payment-return'
				companyId: companyId

		#/office/:companyId/payment(/)
		#/office/:companyId/payment(/)?order_id=:orderId
		payment: (companyId, orderId) =>
			orderId = Iconto.shared.helpers.navigation.getQueryParams()['order_id'] - 0 || 0;
			if orderId
				order = new Iconto.REST.Order id: orderId
				order.fetch()
				.then (order) =>
					Iconto.shared.loader.load('payment')
					.then =>
						updateWorkspace
							page: 'payment'
							companyId: companyId
							orderId: orderId
							order: order
				.catch (error) =>
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()

		addTransaction: (companyId) =>
			updateWorkspace
				page: 'add-transaction'
				companyId: companyId

		settingMessages: (companyId) =>
			updateWorkspace
				page: "settings"
				subpage: "messages"
				companyId: companyId

		faqQuestion: (companyId=null, faqQuestionId=null) =>
			updateRightWorkspace
				page: "settings"
				subpage: "add-faq-question"
				companyId: companyId
				faq:
					type: 'q'
					id: faqQuestionId

		faqTheme: (companyId=null, faqThemeId=null) =>
			updateRightWorkspace
				page: "settings"
				subpage: "add-faq-theme"
				companyId: companyId
				faq:
					type: 'c'
					id: faqThemeId

		#*other
		pageNotFound: ->
			updateWorkspace
				page: 'pageNotFound'
