@Iconto.module 'office.views.money', (Money) ->
	class Money.DepositOperationItemView extends Marionette.ItemView
		template: JST['office/templates/money/deposit-operation-item']
		className: 'deposit-operation-item-view button list-item'

		templateHelpers: ->
			getSign: =>
				switch @model.get('type')
					when Iconto.REST.DepositOperation.TYPE_ADD
						'+'
					when Iconto.REST.DepositOperation.TYPE_DEBIT, Iconto.REST.DepositOperation.TYPE_HOLD
						'-'

	class Money.DepositOperationsView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
		template: JST['office/templates/money/deposit-operations']
		className: 'deposit-operations-view mobile-layout l-pb-0'
		childView: Money.DepositOperationItemView
		childViewContainer: '.list'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
			InfiniteScroll:
				scrollable: '.view-content'

		ui:
			balance: '.deposit-balance'
			commitFromAccountButton: '[name=commit-from-account]'
			commitFromCardButton: '[name=commit-from-card]'
			date_from: '[name=date_from]'
			date_to: '[name=date_to]'

		events:
			'click .reset-date': 'onResetDateClick'

			'click .reset-date-from': 'onResetDateFromClick'
			'click .reset-date-to': 'onResetDateToClick'

		modelEvents:
			'change:date_from': 'onDateFromChange'
			'change:date_to': 'onDateToChange'

		collectionEvents:
			'add remove reset': 'onCollectionChange'

		getQuery: =>
			dateFrom = @state.get('dateFrom')
			dateTo = @state.get('dateTo')
			#
			if dateFrom
				dateFrom = moment(dateFrom)
				if dateFrom.isValid()
					dateFrom = dateFrom.unix()

			if dateTo
				dateTo = moment(dateTo)
				if dateTo.isValid()
					dateTo.add(1, 'days')
					dateTo = dateTo.unix()

			query =
				company_id: @state.get('companyId')
				deposit_id: @model.get('id')

			query.begin_date = dateFrom if dateFrom
			query.end_date = dateTo if dateTo
			query

		bindingSources: =>
			state: @state
			deposit: @model
			legalEntity: @legalEntity

		initialize: =>
			@state = new Iconto.office.models.StateViewModel @options
			@state.set
#				topbarTitle: 'Деньги'
#				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal, leadingComma: true)}"
				isEmpty: false
				isLoadingMore: false

				dateFrom: ''
				dateTo: ''

				modelIsValid: true
				showResetDate: false

			@infiniteScrollState.set limit: 15

			@state.on 'change:dateFrom', _.debounce @reload, 500
			@state.on 'change:dateTo', _.debounce @reload, 500

			@legalEntity = new Iconto.REST.LegalEntity @options.legal
			@model = new Iconto.REST.Deposit
				id: @options.legal.deposit_id or 0
				companyId: @options.companyId

			@collection = new Iconto.REST.DepositOperationCollection()

			@listenTo @infiniteScrollState, 'change:isLoadingMore', (infiniteScrollState, isLoadingMore) =>
				@state.set 'isLoadingMore', isLoadingMore

		onRender: =>
			Backbone.Validation.bind @ #TODO: find some time to figure out how to bind validation to multiple models

			if @model.get('id')
				# has deposit
				@model.fetch({}, reload: true)
				.then =>
					@preload()
					.then =>
						@onCollectionChange()
				.catch (error) =>
					console.error error
				.done =>
					@state.set 'isLoading', false
			else
				@state.set isLoading: false

			unless Modernizr.inputtypes.date
				@state.set
					showResetDate: true

		reload: =>
			@infiniteScrollState.set
				offset: 0
				complete: false
			@collection.reset()
			@promise.cancel() if @promise
			@promise = @preload()
			.catch (error) =>
				console.error error
				unless error instanceof Promise.CancellationError
					Iconto.shared.views.modals.ErrorAlert.show error

		onCollectionChange: =>
			@state.set 'isEmpty', @collection.length is 0

		onDateFromChange: =>
			date_from = @model.get 'date_from' # Получаем дату начала
			date_to = @model.get 'date_to' # Получаем дату конца

			# Если дата больше установленной в helpers или была удалена
			if Iconto.shared.helpers.dateValidation.yearValidation(date_from) or date_from is ''

				# Если не пустая - устанавливаем соответствующую валидацию
				if date_from isnt ''
					@ui.date_to.attr 'min', date_from
					_.extend @model.validation,
						date_to:
							required: false
							minUnixDate: moment(date_from).subtract(1, 'days').format('YYYY-MM-DD')
							maxUnixDate: moment().format('YYYY-MM-DD')

					# Если пустая - дефолтная валидация
				else
					@ui.date_to.attr 'min', ''
					_.extend @model.validation,
						date_to:
							required: false
							maxUnixDate: moment().format('YYYY-MM-DD')

				# Проверяем все поля после изменения условий валидации
				@model.validate()

				# Если все хорошо
				if @model.isValid()
					# Сеттим значение и говорим, что модель валидная
					@state.set
						dateFrom: date_from
					@state.set 'modelIsValid', true

					# Или кидаем ошибку, и очищаем экран
				else
					@state.set 'modelIsValid', false

		onDateToChange: =>
			date_to = @model.get 'date_to'
			date_from = @model.get 'date_from'

			if Iconto.shared.helpers.dateValidation.yearValidation(date_to) or date_to is ''

				if date_to isnt ''
					@ui.date_from.attr 'max', date_to
					_.extend @model.validation,
						date_from:
							required: false
							maxUnixDate: moment(date_to).format('YYYY-MM-DD')

				else
					@ui.date_from.attr 'max', moment().format('YYYY-MM-DD')
					_.extend @model.validation,
						date_from:
							required: false
							maxUnixDate: moment().format('YYYY-MM-DD')

				@model.validate()

				if @model.isValid()
					@state.set
						dateTo: date_to
					@state.set 'modelIsValid', true
				else
					@state.set 'modelIsValid', false

		onResetDateFromClick: =>
			@model.set
				date_from: ''
			@$('input[name=date_from]').parent().find('input[data-is-datepicker]').val('').change()

		onResetDateToClick: =>
			@model.set
				date_to: ''
			@$('input[name=date_to]').parent().find('input[data-is-datepicker]').val('').change()