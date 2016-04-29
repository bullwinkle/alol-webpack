@Iconto.module 'office.views', (Views) ->
	Views.factory = (state) ->
		ViewClass = switch state.page

			when 'index'
				switch state.subpage
					when 'welcome'
					#/office
						Views.index.WelcomeView
					when 'new-company'
					#/office/new
						Views.new.NewCompanyWizardLayout
					when 'new-legal'
					#/office/new/legal
						Views.index.LegalView
					else
					#/office
						Views.index.CompaniesView

			when 'user-profile'
				switch state.subpage
					when 'blacklist'
					#/office/profile/blacklist
						Iconto.shared.views.userProfile.BlacklistView
					when 'mastercards'
					#/office/profile/mastercards
						Iconto.shared.views.userProfile.MasterCardsView
					when 'password'
					#/office/profile/password
						Iconto.shared.views.userProfile.PasswordView
					when 'edit'
					#/office/profile/edit
						Iconto.shared.views.userProfile.ProfileEditView
					else
					#/office/profile
						Iconto.shared.views.userProfile.ProfileView

			when 'branding'
			#/office/:companyId/branding
				Views.company.BrandingView

			when 'spots'
			#/office/:companyId/spots
				Views.company.SpotsView

			when 'documents'
			#/office/:companyId/documents
				Views.company.DocumentsView

			when 'edit'
			#/office/:companyId/edit
				Views.company.EditView

			when 'addresses'
			#/office/:companyId/addresses
				Views.company.AddressesView

			when 'shop'
				switch state.subpage
					when 'goods'
						Views.shop.GoodsView
					when 'orders'
						Views.shop.OrdersView
					when 'ordersEdit'
						Views.shop.OrdersEditView
					when 'editGoods'
						Views.shop.EditGoodsView
					when 'editCategories'
						Views.shop.EditCategoriesView
					else
						Views.shop.ShopView

			when 'employees'
				switch state.subpage
					when 'new'
					#/office/:companyId/employees/new
						Views.company.EmployeesNewView
					else
					#/office/:companyId/employees
						Views.company.EmployeesView

			when 'company-profile'
			#/office/:companyId/profile
				Views.company.ProfileView

			when 'address'
			#/office/:companyId/address/:addressId
				Views.company.AddressView

			when 'legal'
			#/office/:companyId/legal/:legalId
				Views.company.LegalView


			when 'offers'
				switch state.subpage
					when 'user-registration'
						Views.cashback.UserRegistrationView
					when 'coupons'
						Views.offers.CouponsView
					when 'coupon'
						switch state.mode
							when 'edit', 'new'
								Views.offers.CouponEditView
							when 'view'
								Views.offers.CouponView
					when 'advertisements'
						Views.offers.AdvertisementsView
					when 'advertisement'
						switch state.mode
							when 'edit', 'new'
								Views.offers.AdvertisementEditView
							when 'view'
								Views.offers.AdvertisementView

					when 'cashbacks'
						switch state.mode
							when 'personal'
								Views.offers.PersonalCashbacksView
							else
								Views.offers.CashbacksView
					when 'cashback'
						Views.offers.CashbackEditView

					when 'promotions'
						switch state.mode
							when 'personal'
								Views.offers.PersonalPromotionsView
							else
								Views.offers.PromotionsView
					when 'promotion'
						Views.offers.PromotionEditView

					when 'requests'
						switch state.mode
							when 'wishes'
								Views.offers.WishRequestsView
							else
								Views.offers.RequestsView
					when 'request'
						Views.offers.RequestEditView
		# else
		# 	Views.cashback.Layout

			when 'offer'
				switch state.subpage
					when 'new', 'edit'
						Views.cashback.Edit
		# when 'cashback'
		# 	Views.cashback.Layout
		# when 'cashbackEdit'
		# 	Views.cashback.Edit

			when 'history'
				Views.history.TransactionsView

			when 'terms', 'agreement'
				Views.TermsView

			when 'about'
				Views.about.AboutItemView

			when 'friends'
				Views.friends.Layout

			when 'conversations'
				Views.conversations.Layout

			when 'history-cashback-info'
				Views.history.CashbackInfoView

			when 'history-discount-info'
				Views.history.DiscountInfoView

			when 'customers'
				switch state.subpage
					when 'upload'
						Views.customers.CustomersUpload
					else
						Views.customers.CustomersView

			when 'customer'
				switch state.subpage
					when 'edit', 'new'
						Views.customers.CustomerView

			when 'deposit'
				switch state.subpage
					when 'bill'
						Views.deposit.Bill
					when 'addition'
						Views.deposit.Addition
					else
						Views.deposit.DepositList

			when 'money'
				switch state.subpage
					when 'bill'
						Views.money.DepositBillView
					when 'commit'
						Views.money.DepositCommitView
					else
						Views.money.DepositOperationsView

			when 'profile'
				switch state.subpage
					when 'index'
						Views.company.CompanyProfile
					when 'legalEdit'
						Views.company.CompanyProfileEditView
					when 'addressEdit'
						Views.company.AddressEditModal
					when 'spots'
						Views.company.BrandedEntryView
					when 'preview'
						Views.company.Preview

			when 'profile-edit'
				Views.profile.MerchantProfileEditView

			when 'company'
				Views.index.Layout

			when 'partners'
				Views.partners.Layout

			when 'partner'
				switch state.mode
					when 'new'
						Views.partners.NewPartnerView

			when 'company-friend-requests'
				Views.requests.Layout
			when 'company-info'
				Views.partners.CompanyInfo
			when 'company-addresses'
				Views.partners.CompanyAddresses
			when 'company-requests'
				Views.index.CompanyRequests
			when 'request-edit'
				Views.index.CompanyAddLayout
		# when 'company-add-legalentity'
		# 	Views.index.AddLegalEntity
		# when 'company-add-address'
		# 	Views.index.AddAddress

			when 'messages'
				switch state.subpage
					when 'chats'
						Views.messages.ChatsView
					when 'chat'
						if state.chatId
							Views.messages.ChatView
						else
							Views.messages.NewChatView
					when 'deliveries'
						Views.messages.DeliveriesView
					when 'delivery'
						Views.messages.DeliveryView
					when 'new-delivery'
						Views.messages.deliveries.new.Layout
					when 'reviews'
						Views.messages.ReviewsView
					when 'settings'
						Views.messages.SettingsView

			when 'analytics'
				switch state.subpage
					when 'operations'
						Views.analytics.TransactionsView
					when 'payment-return'
						Views.analytics.TransactionsReturnView
					else
						Views.analytics.TransactionsView

			when 'payment'
				Iconto.payment.views.Layout

			when 'add-transaction'
				Views.AddTransaction

			when 'settings'
				switch state.subpage
					when 'messages'
						Views.company.settings.MessagesSettingsView
					when "add-faq-question"
						Views.company.settings.FAQuestionEditView
					when "add-faq-theme"
						Views.company.settings.FAQThemeEditView
					else
						Iconto.shared.views.PageNotFound

			when 'pageNotFound'
				Iconto.shared.views.PageNotFound

		unless ViewClass
			throw new Error("Unable to find view class for #{state.page} page")
		ViewClass
