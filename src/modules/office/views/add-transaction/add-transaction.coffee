@Iconto.module 'office.views', (Views) ->
	class ViewModel extends Backbone.DeepModel
		defaults:
			phone: ''
			client: (new Iconto.REST.User())
			amount: 0
			discountPercent: 0
			totalAmount: 0
			totalDiscount: 0
			address_id: 0
			addresses: []
			employee_id: 0
			employees: []

		validation:
			phone:
				required: true
				pattern: 'phone'
			amount:
				required: true
				pattern: 'number'
				min: 0
				max: 1000000000
			discountPercent:
				required: false
				pattern: 'number'
				min: 0
				max: 100

	class Views.AddTransaction extends Marionette.ItemView
		template: JST['office/templates/add-transaction/add-transaction']
		className: 'add-transaction mobile-layout'
		behaviors:
			Epoxy: {}
			Layout: {}
			Form:
				submit: 'form'
				events:
					submit: 'form'
				validated: ['model']

		ui:
			phoneInput: "input[name=phone]"
			select: 'select'
			form: 'form'
			topbarRightButton: '.topbar-region .right-small'

		events:
			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'

		modelEvents: ->
			'change': 'onDataChanged'
			'change:phone': _.debounce @onPhoneChange, 800

		initialize: ->
#			@options.topbarRightButtonClass = "right-small text-button"
#			@options.topbarRightButtonSpanText = "Подтвердить"

			@state = new Iconto.shared.models.BaseStateViewModel _.extend {}, @options,
				isSaving: false
				isLoadingContact: false
				isValid: true
				tabs: [
					{title: 'Товары', href: "office/#{@options.companyId}/shop"}
					{title: 'Заказы', href: "office/#{@options.companyId}/shop/orders"}
					{title: 'Настройки', href: "office/#{@options.companyId}/shop/orders/edit"}
					{title: 'Добавить транзакцию', href: "/office/#{@options.companyId}/add-transaction", active: true}
				]

			window.model = @model = new ViewModel
				company_id: @state.get('companyId')
			@transactionCompany = new Iconto.REST.TransactionCompany()

			Backbone.Validation.bind @


		onRender: =>
#			@ui.topbarRightButton.attr
#				type: 'submit'
#				form: @ui.form.attr('id')

			@model.trigger 'change:phone'
			@state.set 'isLoading', false

			addressesPromise = (new Iconto.REST.AddressCollection()).fetchAll
				company_id: @state.get 'companyId'

			employeesPromise = (new Iconto.REST.ContactCollection()).fetchAll
				company_id: @state.get 'companyId'
			.then (employees) =>
				ids = _.pluck employees, 'user_id'
				(new Iconto.REST.UserCollection()).fetchByIds ids

			Q.all [
				addressesPromise
				employeesPromise
			]
			.then ([addresses, employees]) =>
				@model.set {addresses, employees}
				@ui.select.selectOrDie('update')
			.catch (err) =>
				console.error arguments
			.done()

#			@model.validate()

		onTopbarRightButtonClick: =>
			console.log 'onTopbarRightButtonClick'
#			e.preventDefault()
#			return false unless @model.isValid()

		onPhoneChange: =>
			if @model.get('phone').length < 8 or !@state.get('companyId')
				return @model.set 'client', (new Iconto.REST.User()).toJSON()

			@state.set 'isLoadingContact', true
			(new Iconto.REST.CompanyClientCollection()).fetch {
				phone: @model.get('phone')
				company_id: @state.get 'companyId'
			}, {reload: true}
			.then (res) =>
				@model.set 'client', _.get(res, '[0]')
			.catch (err) =>
				console.error err
				@model.set 'client', (new Iconto.REST.User()).toJSON()
			.done =>
				defer = =>
					@state.set 'isLoadingContact', false
					@ui.phoneInput.focus()
				setTimeout defer, 300

		onDataChanged: =>
			isValid = model.isValid(['amount', 'discountPercent'])
			if !isValid
				return @state.set 'isValid', false

			@state.set 'isValid', true
			@calculateResult()

		onFormSubmit: (e) =>
			e.preventDefault()

			return false if @state.get('isSaving')
			@state.set('isSaving', true)

			return false unless @model.isValid()

#			@state.set 'topbarRightButtonDisabled', true
			(new Iconto.REST.TransactionCompany()).save
				company_id: @model.get('company_id')
				amount: @model.get 'amount'
				discount: @model.get 'totalDiscount'
				phone: @model.get 'phone'
				payment_time: Date.now()
				address_id: @model.get('address_id') if @model.get('address_id')
			.then (res) =>
				console.log res
				alertify.success 'Транзакция успешно добавлена'
			.dispatch(@)
			.catch (err) =>
				console.error err
				switch err.status
					when 208111
						Iconto.shared.views.modals.ErrorAlert.show
							message: 'Введен неверный формат номера телефона'
					when 208115
						Iconto.shared.views.modals.ErrorAlert.show
							message: 'Необходимо выбрать адрес'
			.done =>
#				@state.set 'topbarRightButtonDisabled', false
				@state.set('isSaving', false)

		calculateResult: =>
			# input
			amount = @model.get 'amount'
			discountPercent = @model.get 'discountPercent'

			# check
			return false if !amount

			# calculation
			totalDiscount = (amount / 100) * discountPercent
			totalAmount= amount - totalDiscount

			# output
			@model.set 'totalAmount', +totalAmount.toFixed(2)
			@model.set 'totalDiscount', +totalDiscount.toFixed(2)