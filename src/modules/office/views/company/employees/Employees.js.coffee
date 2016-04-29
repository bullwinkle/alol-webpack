@Iconto.module 'office.views.company', (Company) ->
	class EmployeeItemView extends Marionette.ItemView
		template: JST['office/templates/company/employees/employee-item']
		className: 'employee'
		attributes: ->
			'data-id': @model.get('id')

		ui:
			deleteButton: '.delete-button'
			sendSmsSwitch: '[type=checkbox]'

		events:
			'click @ui.deleteButton': 'onDeleteButtonClick'
			'change @ui.sendSmsSwitch': 'onSendSmsSwitchChange'

		initialize: =>
			unless @model.get('user').nickname
				@model.get('user').nickname = "Пользователь #{@model.get('user').id}"

		onDeleteButtonClick: =>
			@trigger 'employee:delete', @model

		onSendSmsSwitchChange: =>
			@model.save(send_sms: !@model.get('send_sms'))
			.dispatch(@)
			.catch (error) ->
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

	class Company.EmployeesView extends Marionette.CompositeView
		template: JST['office/templates/company/employees/employees']
		className: 'office-employees-view mobile-layout'
		childView: EmployeeItemView
		childViewContainer: '.employees'

		behaviors:
			Epoxy: {}
			Layout:
				outlets:
					officeTopbar: JST['office/templates/office-topbar']

		serializeData: =>
			_.extend @model.toJSON(), company: @options.company

		initialize: =>
			@model = new Backbone.Model()
			@collection = new Iconto.REST.ContactCollection()

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Сотрудники'
				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal,
					leadingComma: true)}"
				isLoading: false
				breadcrumbs: [
					{title: 'Профиль', href: "office/#{@options.companyId}/profile"}
					{title: 'Настройки профиля компании', href: "#"}
				]
				officeTopbar:
					currentPage: 'employees'

		onRender: =>
			@collection.fetchAll(company_id: @options.company.id, {silent: true})
			.then (employees) =>
				employees = _.unique employees, false, (e) -> e.user_id
				userIds = _.compact _.pluck employees, 'user_id'

				(new Iconto.REST.UserCollection()).fetchByIds(userIds)
				.then (users) =>
					_.each employees, (employee) =>
						employee.user = _.find users, (user) =>
							employee.user_id is user.id
						employee.current_user_id = @options.user.id
					@collection.reset employees
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onChildviewEmployeeDelete: (view, model) =>
			Iconto.shared.views.modals.Confirm.show
				title: 'Удаление сотрудника'
				message: 'Вы уверены, что хотите удалить сотрудника?'
				onSubmit: =>
					(new Iconto.REST.Contact(id: model.get('id'))).destroy()
					.then =>
						@collection.remove(model)
					.dispatch(@)
					.catch (error) =>
						console.error error
						Iconto.shared.views.modals.ErrorAlert.show error
					.done()