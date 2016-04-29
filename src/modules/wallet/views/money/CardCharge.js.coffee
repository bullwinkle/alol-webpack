@Iconto.module 'wallet.views.money', (Money) ->

	class ChargeModel extends Backbone.Epoxy.Model
		defaults:
			amount: null
			sourceCardId: null
			orderType: Iconto.REST.Order.TYPE_CARD2CARD_TRANSFER

		validation:
			sourceCardId:
				required: true
				minLength: 4
				pattern: 'digits'
			amount:
				required: true
				pattern: 'number'
				max: 10000


	class Money.CardCharge extends Marionette.ItemView
		className: 'card-charge-view mobile-layout'
		template: JST['wallet/templates/money/card-charge']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		ui:
			topbarLeftButton: '.topbar-region .left-small'
			chargeCommit: '.charge-commit'
			select: 'select.card'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
			'click @ui.chargeCommit': 'onChargeCommitClick'

		modelEvents:
			'change:amount': 'onAmountChange'
			'validated:valid': 'onModelValid'
			'validated:invalid': 'onModelInvalid'

		initialize: =>
			@card = new Iconto.REST.Card id: @options.cardId
			@model = new ChargeModel()
			@state = new Iconto.wallet.models.StateViewModel @options
			@state.set
				topbarSubtitle: 'Пополнение баланса'
				topbarLeftButtonClass: ''
				topbarLeftButtonSpanClass: 'ic-chevron-left'
				isLoading: true
				cards: []
				chargeCommitButtonDisabled: true

			Backbone.Validation.bind @;

		bindingSources: =>
			chargeModel: => @model

		onRender: =>
			@card.fetch()
			.then =>
				@state.set
					topbarTitle: "#{ @card.get 'title' } - #{ (@card.get 'card_number') }"
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert error
			.done()

			(new Iconto.REST.CardCollection()).fetchAll(blocked: false, activated: true)
			.then (cards) =>
				cards = _.reject cards, (card) =>
					card.id is @card.get('id')
				_.each cards, (card) ->
					_.extend card,
						label: "#{card.title} #{card.card_number}"
						value: card.id
				@state.set
					cards: cards
					isLoading: false
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert error
			.done()

		onAmountChange:=>
			@ui.select.trigger 'change'

		onModelValid: =>
			@state.set 'chargeCommitButtonDisabled', true

		onModelInvalid: =>
			@state.set 'chargeCommitButtonDisabled', false

		onTopbarLeftButtonClick: =>
			Iconto.wallet.router.navigate "/wallet/money/card/#{ @state.get 'cardId' }", trigger: true

		onChargeCommitClick: =>
			sourceCardId = @model.get('sourceCardId') - 0
			#Если в качестве источника выбрана "другая карта" - хотите ли зарегистрировать и привязать новую?
			unless sourceCardId

				Iconto.shared.views.modals.Confirm.show
					title: "Новая карта"
					message: "Хотите зарегистрировать новую карту?"
					onSubmit: =>
						@model.set 'orderType', Iconto.REST.Order.TYPE_CARD_REGISTRATION
						@placeOrder()
					onCancel: =>
						@model.set 'orderType', Iconto.REST.Order.TYPE_CARD2CARD_TRANSFER
						@placeOrder()

			else @placeOrder()


		placeOrder: =>
			sourceCardId = @model.get('sourceCardId') - 0

			order =
				destination_card_id: @card.get('id')
				source_card_id: sourceCardId if sourceCardId
				amount: @model.get('amount') - 0
				type: @model.get('orderType') - 0
				redirect_url: document.location.href

			unless (order.destination_card_id and order.amount and order.amount <= 10000)
				Iconto.shared.views.modals.ErrorAlert message: 'Некорректные данные'
			else
				(new Iconto.REST.Order(order)).save()
				.then (response) =>
					Iconto.wallet.router.navigate "/wallet/payment?order_id=#{response.order_id}", trigger: true
#					Iconto.shared.helpers.navigation.tryNavigate response.form_url
				.catch (error) =>
					console.error error
					Iconto.shared.views.modals.ErrorAlert error
				.done()
