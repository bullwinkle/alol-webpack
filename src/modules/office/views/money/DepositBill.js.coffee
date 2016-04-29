@Iconto.module 'office.views.money', (Money) ->
	class BillModel extends Backbone.Model
		defaults:
			amount: 0
			company_id: 0
			deposit_id: 0

		validation:
			amount:
				required: true
				pattern: 'number'
				min: 1
				max: 9999999999.99
			company_id:
				required: true
			deposit_id:
				required: true

	_.extend BillModel::, Backbone.Validation.mixin

	class Money.DepositBillView extends Marionette.ItemView
		template: JST['office/templates/money/deposit-bill']
		className: 'deposit-bill-view mobile-layout'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		ui:
			submit: 'button[type=submit]'
			topbarLeftButton: '.topbar-region .left-small'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
			'submit form': 'onFormSubmit'
			'click [name=cancel]': 'onClickCancel'

		initialize: =>
			@model = new BillModel
				company_id: @options.companyId
				deposit_id: @options.legal.deposit_id
				legal_id: @options.legal.id

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Сформировать счет'
				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal,
					leadingComma: true)}"
				email: @options.company.email
				isLoading: false

				hasAddressCredentials: @options.legal.country_id and @options.legal.city_id and @options.legal.address

				breadcrumbs: [
					{title: 'Деньги', href: "office/#{@model.get('company_id')}/money"}
					{title: 'Пополнение с расчетного счета', href: "#"}
				]

			Backbone.Validation.bind @

		stopPolling: =>
			if @task
				#have a running task - stop it
				@task.stopPolling()
				@task = null

		onFormSubmit: (e) =>
			e.preventDefault()

			return false unless @model.isValid(true)

			@ui.submit.prop('disabled', true).addClass('is-loading')
			model = @model.toJSON()
			@stopPolling()

			@task = new Iconto.REST.Task
				type: Iconto.REST.Task.TYPE_GENERATE_BILL
				args: model

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
								message: "Счет сформирован и отправлен на электронный адрес #{@options.company.email}"
								onCancel: =>
									Iconto.office.router.navigate "office/#{@state.get('companyId')}/money", trigger: true
						when Iconto.REST.Task.STATUS_ERROR
							if @task.get('code') is 4042111140
								@task.set message: 'Для выставления счета необходимо заполнить адрес на странице юридического лица компании'
							Iconto.shared.views.modals.ErrorAlert.show
								status: '' || @task.get('code')
								msg: task.get('message')
								onCancel: =>
									@ui.submit.prop('disabled', false)
						when Iconto.REST.Task.STATUS_TIMEOUT
							Iconto.shared.views.modals.ErrorAlert.show status: '', msg: "Превышено время ожидания"

					unless status is Iconto.REST.Task.STATUS_PROCESSING
						@model.validate()
						@ui.submit.prop('disabled', false).removeClass('is-loading')

				console.log 'start polling'
				@task.poll(30) #start polling 30 times

		onBeforeDestroy: =>
			@stopPolling()

		onClickCancel: =>
			Iconto.office.router.navigate "office/#{@state.get('companyId')}/money", trigger: true