@Iconto.module 'wallet.views.money', (Money) ->
	class CardItemView extends Marionette.ItemView
		template: JST['wallet/templates/money/card-item']
		className: 'card-item-view bank-card-info'
		attributes: ->
			'data-card-id': @model.get('id')

		events:
			'click': 'onClick'
			'click .verify-button': 'onVerifyButtonClick'

		initialize: =>
			@model.set card_number: @model.get('card_number').replace(/x/gi, '*')

		onClick: =>
			Iconto.wallet.router.navigate "wallet/money/card/#{@model.get('id')}", trigger: true

		onVerifyButtonClick: (e) =>
			e.preventDefault()
			e.stopPropagation()

			Iconto.shared.views.modals.Confirm.show
				title: 'Cashback by АЛОЛЬ'
				message: 'Подтвердите карту, чтобы мы точно знали, что она ваша, и тогда Вы сможете просматривать историю начисления CashBack.'
				submitButtonText: 'Подтвердить'
				onSubmit: =>
					return false if @onVerifyButtonClickLock
					@onVerifyButtonClickLock = true
					data =
#						type: Iconto.REST.Order.TYPE_CARD_VERIFICATION
						source_card_id: @model.get('id')
						redirect_url: document.location.href

					if @model.get('pan_id')
						data.type = Iconto.REST.Order.TYPE_CARD_VERIFICATION
					else
						data.type = Iconto.REST.Order.TYPE_CARD_REGISTRATION

					cardVerificationOrder = new Iconto.REST.Order()
					cardVerificationOrder.save(data)
					.then (response) =>
#						Iconto.shared.helpers.navigation.tryNavigate response.form_url
						Iconto.wallet.router.navigate "/wallet/payment?order_id=#{response.order_id}", trigger: true
					.catch (error) =>
						console.error error
						Iconto.shared.views.modals.ErrorAlert.show error
					.done =>
						@onVerifyButtonClickLock = false

	class CardsView extends Marionette.CompositeView
		className: 'mobile-layout money-layout cards-view'
		template: JST['wallet/templates/cards']
		childView: Money.CardItemView
		childViewContainer: '.list'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		collectionEvents:
			'add remove reset': 'onCollectionChange'

		ui:
			transferButton: '[name=transfer]'

		events:
			'click @ui.transferButton': "onTransferButtonClick"

		initialize: =>
			@state = new Iconto.wallet.models.StateViewModel @options
			@state.set
#				topbarTitle: 'Деньги'
				balance: @options.user.balance
				isCashbacksPage: false
				isLoadingMore: false
				isLoading: false

				tabs: [
					{title: 'Мои карты', href: '/wallet/cards', active: true},
					{title: 'История', href: '/wallet/money/cashback'}
				]

				isEmpty: false

			@collection = new Iconto.REST.CardCollection()

		onRender: =>
			(new Iconto.REST.User(id: Iconto.api.userId)).fetch({}, {reload: true})
			.then (user) =>
				@state.set balance: user.balance
			.dispatch(@)
			.catch (error) =>
				console.error error
			.done()

			@state.set 'isLoadingMore', true
			(new Iconto.REST.CardCollection()).fetchAll(blocked: false)
			.then (cards) =>
				bankIds = _.unique _.compact _.pluck cards, 'bank_id'
				bankPromise = (new Iconto.REST.BankCollection()).fetchByIds(bankIds)
				.then (banks) =>
					for card in cards
						card.bank = _.find banks, (bank) ->
							bank.id is card.bank_id
						card.bank ||= new Iconto.REST.Bank().toJSON()
				paymentSystemIds = _.unique _.compact _.pluck cards, 'system_id'
				paymentSystemPromise = (new Iconto.REST.PaymentSystemCollection()).fetchByIds(paymentSystemIds)
				.then (paymentSystems) =>
					for card in cards
						card.paymentSystem = _.find paymentSystems, (paymentSystem) ->
							paymentSystem.id is card.system_id
						card.paymentSystem ||= new Iconto.REST.PaymentSystem().toJSON()
				Q.all([bankPromise, paymentSystemPromise])
				.then =>
					@collection.reset cards
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set
					isLoadingMore: false

		onCollectionChange: =>
			@state.set 'isEmpty', @collection.length is 0

		onTransferButtonClick: =>
			Iconto.wallet.router.navigate "/wallet/money/withdraw", trigger: true
			return false

			if @options.user.personal_info_status in [Iconto.REST.User.PERSONAL_INFO_STATUS_CANCEL,
			                                          Iconto.REST.User.PERSONAL_INFO_STATUS_EMPTY]
				Iconto.shared.views.modals.Confirm.show
					message: 'Для осуществления операций с денежными средствами в соответствии с требованиями законодательства необходимо пройти процедуру идентификации.'
					submitButtonText: 'Пройти процедуру'
					cancelButtonText: 'Позже'
					onSubmit: =>
						Iconto.wallet.router.navigate "/wallet/profile/verification", trigger: true
			else if @options.user.personal_info_status is Iconto.REST.User.PERSONAL_INFO_STATUS_PENDING
				Iconto.shared.views.modals.Alert.show
					title: 'Данные в обработке'
					message: 'Процедура обработки данных занимает от 24 часов. Спасибо за ожидание!'
					onSubmit: =>
						Iconto.wallet.router.navigate "/wallet/profile/verification/status", trigger: true
			else
				Iconto.wallet.router.navigate "/wallet/money/withdraw", trigger: true