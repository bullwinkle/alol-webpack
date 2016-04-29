@Iconto.module 'wallet.views.money', (Money) ->
	class WithdrawModel extends Backbone.Model
		defaults:
			withdrawAmount: 0
			transferAmount: 0

		validation:
			withdrawAmount:
				pattern: 'number'
			transferAmount:
				pattern: 'number'

	class Money.CashbackWithdrawView extends Marionette.ItemView
		className: 'cashback-withdraw-view mobile-layout'
		template: JST['wallet/templates/money/cashback-withdraw/withdraw']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
			ValidatedForm: {}

		ui:
#			card: '.card'
			withdrawAmountInput: '[name=withdrawAmount]'
			transferAmountInput: '[name=transferAmount]'
			continueButton: '.continue-button'

		events:
#			'click @ui.card': 'onCardClick'
			'click @ui.continueButton': 'onContinueButtonClick'
			'input @ui.withdrawAmountInput': 'onWithdrawAmountInput'
			'input @ui.transferAmountInput': 'onTransferAmountInput'

		bindingSources: ->
			card: @card
			bank: @bank

		bindingFilters:
			replacePan: (pan) ->
				pan.replace(/x/g, "*")

		initialize: =>
			@options.phoneNumber ||= ''
			@model = new WithdrawModel @options;

			@card = new Iconto.REST.Card(id: @options.cardId)
			@bank = new Iconto.REST.Bank()

			@options.user.balance = if @options.user.balance < 0 then 0 else @options.user.balance

			@state = new Iconto.wallet.models.StateViewModel @options
			@state.set
				topbarTitle: 'Перевод'
				isLoading: true
				breadcrumbs: [
					{title: 'Мои карты', href: '/wallet/cards'}
					# navigationg by wizard here, so this link is broken
					# {title: 'Выбор карты', href: '/wallet/money/withdraw'}
					{title: 'Перевод', href: '/wallet/money/withdraw'}
				]
				moneyAvailable: @options.user.balance
				canWithdraw: false
				minimumWithdraw: 0
				feePercent: 0

		onRender: =>
			@card.fetch()
			.then =>
				@bank.set(id: @card.get('bank_id')).fetch()
			.then =>
				params =
					order_type: if @options.phoneNumber then Iconto.REST.Order.TYPE_MONETA_TRANSFER else Iconto.REST.Order.TYPE_CASHBACK_PAYOUT
					amount: 0
				Iconto.api.get('order-fee', params)
			.then (fee) =>
				@fee = fee.data

				@state.set
					isLoading: false
					feePercent: +(@fee.fee_percent * 100).toFixed(1)
					canWithdraw: +(@fee.minimum_fee + @fee.min_amount).toFixed(2) <= @state.get('moneyAvailable')
					minimumWithdraw: +(@fee.minimum_fee + @fee.min_amount).toFixed(2)

				# 30 RUB + 50 RUB = 80 RUB (from server)
				@model.validation.withdrawAmount.min = +(@fee.minimum_fee + @fee.min_amount).toFixed(2)
				# Min(user.balance or orderFee.max_amount) (from server)
				@model.validation.withdrawAmount.max = +(Math.min(@options.user.balance, @fee.max_amount)).toFixed(2)
				# 50 RUB (from server)
				@model.validation.transferAmount.min = @fee.min_amount
				# Min(user.balance or orderFee.max_amount) * @fee.percent
				@model.validation.transferAmount.max = +(Math.min(@options.user.balance,
						@fee.max_amount) * (1 - @fee.fee_percent)).toFixed(2)

			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onShow: =>
			# use breadcrumbs to return to card select view
			$('.breadcrumbs a:eq(1)').click (e) =>
				e.preventDefault()
				@trigger 'transition:destinationSelect'

		onContinueButtonClick: =>
			@$('form').removeClass('hide-validation-errors')

			if @model.isValid(true)

				order = if @options.phoneNumber
					new Iconto.REST.Order
						type: Iconto.REST.Order.TYPE_MONETA_TRANSFER
						amount: @model.get('withdrawAmount')
						redirect_url: "#{document.location.origin}/wallet/money/cashback"
						phone_number: @options.phoneNumber
				else
					new Iconto.REST.Order
						type: Iconto.REST.Order.TYPE_CASHBACK_PAYOUT
						amount: @model.get('withdrawAmount')
						source_card_id: @card.get('id')
						redirect_url: document.location.href.replace 'withdraw', 'cards'

				@ui.continueButton.prop('disabled', true).addClass('is-loading')

				order.save()
				.then (response) =>
					order.invalidate()
					payment = new Iconto.REST.Payment
						order_id: response.order_id
					payment.save()
					.then =>
						Iconto.wallet.router.navigate "/wallet/payment?order_id=#{response.order_id}", trigger: true
				.catch (error) =>
					console.error error
					error.msg = switch error.status
						when 200006 then "Недостаточно средств"
						else
							error.msg
					Iconto.shared.views.modals.ErrorAlert.show error
				.done =>
					@ui.continueButton.prop('disabled', false).removeClass('is-loading')

		onWithdrawAmountInput: =>
			value = +@ui.withdrawAmountInput.val()

			unless _.isNaN(value)
				transferAmount = Math.max(value - (+(Math.max(value * @fee.fee_percent, @fee.minimum_fee)).toFixed(2)), 0)
				@model.set {withdrawAmount: value, transferAmount: transferAmount}, {validate: true}
				@ui.transferAmountInput.val transferAmount
			else
				@model.set {withdrawAmount: value}, {validate: true}

		onTransferAmountInput: =>
			value = +@ui.transferAmountInput.val()

			unless _.isNaN(value)
				maxFixFeeAmount = @fee.fee_percent * 100 * @fee.minimum_fee
				if value + @fee.minimum_fee < maxFixFeeAmount
					withdrawAmount = value + @fee.minimum_fee
				else
					withdrawAmount = value / (1 - @fee.fee_percent)
				withdrawAmount = +(withdrawAmount).toFixed(2)
				@model.set {withdrawAmount: withdrawAmount, transferAmount: value}, {validate: true}
				@ui.withdrawAmountInput.val withdrawAmount
			else
				@model.set {transferAmount: value}, {validate: true}