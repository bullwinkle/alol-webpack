@Iconto.module 'office.views.money', (Money) ->
	class Money.DepositCommitView extends Marionette.ItemView
		template: JST['office/templates/money/deposit-commit']
		className: 'deposit-commit-view mobile-layout'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		ui:
			submit: 'button[type=submit]'
			topbarLeftButton: '.topbar-region .left-small'
			amountInput: '[name=amount]'
			amountWithFeeInput: '[name=amount-with-fee]'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
			'submit form': 'onFormSubmit'
			'input @ui.amountInput': 'onAmountInput'
			'input @ui.amountWithFeeInput': 'onAmountWithFeeInput'
			'click [name=cancel]': 'onClickCancel'

		initialize: =>
			@model = new Iconto.REST.Order
				type: Iconto.REST.Order.TYPE_COMPANY_DEPOSIT_COMMITMENT
				company_id: @options.companyId
				redirect_url: document.location.href
				deposit_id: @options.legal.deposit_id

			@model.validation.amount.min = 1

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Пополнение счета'
				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal, leadingComma: true)}"
				isLoading: false

				amountWithFee: 0.0
				hasAddressCredentials: @options.legal.country_id and @options.legal.city_id and @options.legal.address

				breadcrumbs: [
					{title: 'Деньги', href: "office/#{@options.companyId}/money"}
					{title: 'Пополнение с банковской карты', href: "#"}
				]

			@FEE_PERCENT = 0.01 # 1%

			Backbone.Validation.bind @

		onFormSubmit: (e) =>
			e.preventDefault()
			if @model.isValid()
				@ui.submit.attr('disabled', true)
				@model.save(null, validate: false)
				.then (order) =>
					console.log order
					Iconto.shared.helpers.navigation.tryNavigate(order.form_url)
				.catch (error) =>
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
					@model.validate()
				.done()

		onAmountInput: =>
			value = @ui.amountInput.val().trim()
			@model.set 'amount', value, validate: true
			valueWithFee = if value - 0 then (value * (1 + @FEE_PERCENT)).toFixed(2) else 0
			@ui.amountWithFeeInput.val valueWithFee

		onAmountWithFeeInput: =>
			value = @ui.amountWithFeeInput.val().trim()
			@ui.amountWithFeeInput.val value
			valueWithoutFee = if value - 0 then (value * 0.9).toFixed(2) else value
			@model.set 'amount', valueWithoutFee, validate: true

		onClickCancel: =>
			Iconto.office.router.navigate "office/#{@state.get('companyId')}/money", trigger: true