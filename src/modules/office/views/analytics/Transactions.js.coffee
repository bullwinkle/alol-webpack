@Iconto.module 'office.views.analytics', (Analytics) ->
	class Analytics.TransactionItemView extends Marionette.ItemView
		tagName: 'tr'
		template: JST['office/templates/analytics/transaction-item']
		className: 'transaction-item-view'

	class Analytics.TransactionsView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
		template: JST['office/templates/analytics/transactions']
		className: 'transactions-view mobile-layout'
		childView: Analytics.TransactionItemView
		childViewContainer: '.list'

		behaviors:
			Epoxy: {}
			InfiniteScroll:
				scrollable: '.view-content'

		ui:
			date_from: '[name=date_from]'
			date_to: '[name=date_to]'
			sendButton: '.send'

		events:
			'click .reset-date-from': 'onResetDateFromClick'
			'click .reset-date-to': 'onResetDateToClick'
			'click @ui.sendButton': 'onSendButtonClick'

		modelEvents:
			'change:date_from': 'onDateFromChange'
			'change:date_to': 'onDateToChange'

		initialize: =>
			console.warn @options
			@model = new Iconto.REST.TransactionCompany()

			@model.set
				date_from: moment().subtract(1, 'month').format('YYYY-MM-DD')
				date_to: moment().format('YYYY-MM-DD')


			@collection = new Iconto.REST.TransactionCompanyCollection()

			@state = new Iconto.office.models.StateViewModel @options
			@state.set
#				topbarTitle: 'Аналитика'
#				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal, leadingComma: true)}"
				tabs: [
					title: 'Операции'
					href: "office/#{@options.company.id}/analytics/operations"
					active: @options.subpage is 'operations'
				,
					title: 'Возврат'
					href: "office/#{@options.company.id}/analytics/payment-return"
					active: @options.subpage is 'payment-return'
				]
				isLoading: false
				modelIsValid: true
				isEmpty: true
				isLoadingMore: false

				showResetDate: false
				email: @options.company.email

				dateFrom: ''
				dateTo: ''
				format: 'xls'

		onRender: =>
			Backbone.Validation.bind @ #TODO: find some time to figure out how to bind validation to multiple models

			unless Modernizr.inputtypes.date
				@state.set
					showResetDate: true
			@onDateFromChange()
			@onDateToChange()

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


		stopPolling: =>
			if @task
				#have a running task - stop it
				@task.stopPolling()
				@task = null

		onSendButtonClick: =>
			@ui.sendButton.prop('disabled', true).addClass('is-loading')
			@stopPolling()

			@task = new Iconto.REST.Task
				type: Iconto.REST.Task.TYPE_GENERATE_ANALYTICS
				args:
					company_id: @state.get('companyId')
					begin_date: @state.get('dateFrom')
					end_date: @state.get('dateTo')
					format: @state.get('format')

			@task.save()
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.then (response) =>
				console.info response
				@task.on 'change:status', (task, status) =>
					return false if @isDestroyed
					console.info status, task
					#status changed
					switch status
						when Iconto.REST.Task.STATUS_COMPLETED, false #TODO: motherfucking backend problem
							Iconto.shared.views.modals.Alert.show
								title: "Благодарим Вас!"
								message: "Таблица аналитики сформирована и отправлена на электронный адрес #{@options.company.email}"

						when Iconto.REST.Task.STATUS_ERROR
							Iconto.shared.views.modals.ErrorAlert.show
								status: '' || @task.get('code')
								msg: task.get('message')

						when Iconto.REST.Task.STATUS_TIMEOUT
							Iconto.shared.views.modals.ErrorAlert.show status: '', msg: "Превышено время ожидания"

					unless status is Iconto.REST.Task.STATUS_PROCESSING
						@model.validate()
						@ui.sendButton.prop('disabled', false).removeClass('is-loading')

				console.log 'start polling'
				@task.poll(30) #start polling 30 times

		onBeforeDestroy: =>
			@stopPolling()