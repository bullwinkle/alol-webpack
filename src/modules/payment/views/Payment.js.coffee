#= require ./PaymentSourceItem

@Iconto.module 'payment.views', (Views) ->
	class Views.PaymentView extends Marionette.CompositeView
		className: 'payment-view mobile-layout'
		childView: Views.PaymentSourceItemView
		childViewContainer: ".payment-sources ul"

		template: JST['payment/templates/payment']
		templateHelpers: ->
			getSubmitButtonText: (orderType) ->
				text = switch orderType
					when Iconto.REST.Order.TYPE_CARD_REGISTRATION
						'Зарегистрировать карту'
					when Iconto.REST.Order.TYPE_CARD_VERIFICATION
						'Подтвердить карту'
					else
						'Оплатить'
				text.toUpperCase()

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
			Form:
				submit: 'button[name=submit]'
				events:
					click: 'button[name=submit]'

		ui:
#			topbarLeftButton: '.topbar-region .left-small'
			submitButton: 'button[name=submit]'
			curdNumberInput: '[name=card_number]'

		events:
#			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
#			'click @ui.submitButton': 'onSubmitButtonClick'
			'submit form': 'onSubmitButtonClick'

		modelEvents:
			'validated:valid': ->
				@state.set 'modelIsValid', true
			'validated:invalid': ->
				@state.set 'modelIsValid', false

		bindingFilters:
			feePercent: (fee) ->
				(fee * 100).toFixed(2)

		bindingSources: =>
			order: @order
			orderFee: @orderFee

		validated: =>
			model: @model

		initialize: =>
			#model (Iconto.REST.Payment) is set in PaymentLayout and is passed in @options
			@order = @options.order
			@listenTo @order, 'change:state', @onOrderStatusChange

			@orderFee = new Backbone.Model
				fee_percent: 0
				minimum_fee: 0
				total: 0
				amount: 0

			@state = new Iconto.payment.models.StateViewModel()
			@state.set
				orderId: @order.get('id')
				topbarLeftButtonClass: ''
				topbarTitle: @order.get('description')
				modelIsValid: false
				selectedPaymentSource: null
				isCardRegistration: @order.get('type') is Iconto.REST.Order.TYPE_CARD_REGISTRATION
				isCardVerification: @order.get('type') is Iconto.REST.Order.TYPE_CARD_VERIFICATION
				verificationCardNumber: ''
				sourceCardId: @order.get('source_card_id')

			@state.on 'change:selectedPaymentSource', @onStateSelectedPaymentSourceChange

			@state.addComputed 'paymentSourceFulfilled',
				deps: ['selectedPaymentSource'],
				get: (selectedPaymentSource) ->
					if selectedPaymentSource
						switch selectedPaymentSource.get('type')
							when Views.PaymentSource.TYPE_BOUND_CARD
								selectedPaymentSource.get('card').is_fulfilled
							when Views.PaymentSource.TYPE_OTHER_CARD
								false
							else
								false
					else
						false

#			if not window.ICONTO_WEBVIEW and @order.get('redirect_url')
#				@state.set 'topbarLeftButtonSpanClass', 'ic-chevron-left'

			@collection = new Views.PaymentSourceCollection()

		onRender: =>
			order = @order.toJSON()

#			@$('#month').selectOrDie()
#			@$('#year').selectOrDie()

			Iconto.api.get('order-fee', {order_type: order.type, amount: order.amount})
			.then (response) =>
				throw response unless response.status is 0
				@orderFee.set response.data
				@orderFee.set 'amount', order.amount + response.data.total

				if order.type is Iconto.REST.Order.TYPE_CARD_REGISTRATION
					otherCard = new Views.PaymentSource
						id: 0
						type: Views.PaymentSource.TYPE_OTHER_CARD
					@state.set 'selectedPaymentSource', otherCard
				else if order.type is Iconto.REST.Order.TYPE_CARD_VERIFICATION and order.source_card_id
					(new Iconto.REST.Card(id: order.source_card_id))
					.fetch()
					.then (card) =>
						sourceCard = new Views.PaymentSource
							id: card.id
							card: card
							type: Views.PaymentSource.TYPE_BOUND_CARD
						@state.set
							selectedPaymentSource: sourceCard
							verificationCardNumber: card.card_number
				else
					(new Iconto.REST.CardCollection())
					.fetchAll(blocked: false, activated: true)
					.then (cards) =>
						sources = []
						destinationCardId = @order.get('destination_card_id')
						for card in cards
							continue if destinationCardId and card.id is destinationCardId #don't use source card as a payment source

							source = new Views.PaymentSource
								id: card.id
								card: card
								type: Views.PaymentSource.TYPE_BOUND_CARD
							sources.push source
						otherCard = new Views.PaymentSource
							id: 0
							type: Views.PaymentSource.TYPE_OTHER_CARD
						sources.push otherCard

						@collection.reset sources

						unless order.source_card_id
							otherCardView = @children.find (child) => child.model.cid is otherCard.cid
							otherCardView.$el.trigger('click') if otherCardView
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set isLoading: false

		onBeforeDestroy: =>
			delete @['order']

#		onTopbarLeftButtonClick: =>
#			redirectUrl = @order.get('redirect_url')
#			if redirectUrl
#				@trigger 'transition:exit', redirectUrl

		onChildviewClick: (childView, itemModel) =>
			@$('.payment-sources .active').removeClass('active')
			childView.$el.addClass 'active'
			@state.set 'selectedPaymentSource', itemModel

		onStateSelectedPaymentSourceChange: (state, paymentSource) =>
			cardNumber = ''
			if paymentSource
				card = paymentSource.get('card')

				if paymentSource.get('type') is Views.PaymentSource.TYPE_OTHER_CARD
					card_id = 0
					is_fulfilled = false
				else if card
					card_id = card.id
					is_fulfilled = card.is_fulfilled

					cardNumber = card.card_number

			else
				card_id = 0
				is_fulfilled = false

			@model.set
				card_id: card_id
				is_fulfilled: is_fulfilled
				card_number: ''
				cardholder_name: ''
				cvc: ''
				month: ''
				year: ''

#			if cardNumber
#				@ui.curdNumberInput
#				.val cardNumber
#				.prop 'disabled', true
#			else
#				@ui.curdNumberInput
#				.val ''
#				.prop 'disabled', false

			#"reselect" selected options in selects - lol
			_.defer => @$('option[selected]').prop('selected',true)

		onSubmitButtonClick: (e) =>
			e.preventDefault()
			if @model.isValid(true)
				@trigger 'transition:processing'
