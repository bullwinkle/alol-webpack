@Iconto.module 'wallet.views', (Views) ->
	Views.factory = (state) ->
		ViewClass = switch state.page
			when 'messages'
				switch state.subpage
					when 'chats'
						Views.messages.ChatsView
					when 'chat'
						Views.messages.ChatView
					when 'chat-info'
						Views.messages.ChatInfoView
					when 'new-chat'
						Views.messages.NewChatView
					when 'new-chat-qr'
						Views.messages.NewChatQRView
					when 'settings'
						Views.messages.SettingsView

			when 'money'
				switch state.subpage
					when 'withdraw'
						Views.money.CashbackWithdrawWizardLayout
					when 'payment'
						Views.money.payment.Layout
					when 'card'
						Views.money.CardView
					when 'new-card'
						Views.money.NewCardView
					when 'charge'
						Views.money.CardCharge
					when 'settings'
						Views.money.CardSettings
					when 'transaction'
						if state.cardId
							Views.money.CardTransactionInfoView
						else
							Views.money.TransactionInfoView
					when 'order'
						if state.cardId
							Views.money.CardOrderInfoView
						else
							Views.money.OrderInfoView
					when 'cashback'
						Views.money.CashbacksView
					when 'cards'
						Views.money.CardsView
					when 'mastercard'
						Views.money.MasterCardView
					when 'mastercardGet'
						Views.money.MasterCardGetView

			when 'user-profile'
				switch state.subpage
					when 'edit'
						Iconto.shared.views.userProfile.ProfileEditView
					when 'blacklist'
						Iconto.shared.views.userProfile.BlacklistView
					when 'password'
						Iconto.shared.views.userProfile.PasswordView
					when 'mastercards'
						Iconto.shared.views.userProfile.MasterCardsView
					when 'clientcode'
						Iconto.shared.views.userProfile.ClientCodeView
					else
						Iconto.shared.views.userProfile.ProfileView

			when 'verification'
				switch state.subpage
					when 'confirmation'
						Iconto.shared.views.userProfile.verification.ConfirmationView
					when 'status'
						Iconto.shared.views.userProfile.verification.StatusView
					else
						Iconto.shared.views.userProfile.verification.VerificationView

			when 'terms', 'tariffs'
				Views.TermsView

			when 'about'
				Views.about.AboutItemView

			when 'offers'
				switch state.subpage
					when 'feed', 'favourites'
						Views.offers.FeedView
					when 'company-cashbacks'
						Views.offers.FeedCashbacksView

			when 'offer'
				switch state.objectType
					when 'cashback', 'promotion'
						Views.offers.FeedItemDetailsView
					else
						Iconto.shared.views.PageNotFound

			when 'company'
				switch state.subpage
					when 'offers'
						Iconto.company.views.offers.FeedView
					when 'addresses'
						Views.Map
					when 'address'
						Iconto.company.views.DetailsView
					else
						Iconto.company.views.CompanyView

			when 'company-offers'
				Iconto.company.views.offers.FeedView

			when 'company-offer'
				Iconto.company.views.offers.FeedItemDetailsView

			when 'pageNotFound'
				Iconto.shared.views.PageNotFound

			when 'test'
				Views.TestView

			when 'crop'
				Iconto.shared.views.ImagesCropper

			when 'registrator'
				Views.registrator.RegistratorView

			when 'payment'
				Iconto.payment.views.Layout

			when 'shop'
				Iconto.order.views.ShopLayout

			when 'services'
				switch state.subpage
					when 'taxi'
						Iconto.order.views.TaxiFormView
					else
						Iconto.wallet.views.ServicesLayout

		unless ViewClass
			throw new Error("Unable to find view class for #{state.page} page")
		ViewClass
