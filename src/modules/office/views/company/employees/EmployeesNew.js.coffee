@Iconto.module 'office.views.company', (Company) ->
	class Company.EmployeesNewView extends Marionette.ItemView
		template: JST['office/templates/company/employees/new']
		className: 'office-employees-new-view mobile-layout'

		behaviors:
			Epoxy: {}
			Layout: {}
			Form:
				submit: '[name=save-button]'
				events:
					click: '[name=save-button]'

		ui:
			saveButton: '[name=save-button]'

		validated: ->
			model: @model

		initialize: =>
			@model = new Iconto.REST.Contact
				company_id: @options.company.id

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Добавление сотрудника'
				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal,
					leadingComma: true)}"
				isLoading: false
				breadcrumbs: [
					{title: 'Профиль', href: "office/#{@options.companyId}/profile"}
					{title: 'Настройки профиля компании', href: "office/#{@options.companyId}/employees"}
					{title: 'Добавление сотрудника', href: "#"}
				]
				phone: ''

			@listenTo @state,
				'change:phone': (state, phone) =>
					@model.set phone: "7#{Iconto.shared.helpers.phone.parse(phone)}", @setterOptions

		onFormSubmit: =>
			@model.save(@model.pick('phone', 'send_sms', 'company_id'))
			.then =>
				Iconto.shared.views.modals.Alert.show
					title: 'Готово'
					message: 'Сотрудник успешно добавлен'
					onCancel: =>
						Iconto.office.router.navigate "office/#{@options.company.id}/employees", trigger: true
			.dispatch(@)
			.catch (error) =>
				console.error error
				error.msg = switch error.status
					when 203112, 203113 then "Сотрудник с таким номером телефона уже добавлен"
					else
						"Произошла ошибка, попробуйте позже"
				Iconto.shared.views.modals.ErrorAlert.show error
				console.log error
			.done()