@Iconto.module 'office.views.shop', (Shop) ->
	class Shop.OrdersEditView extends Marionette.ItemView
		className: 'shop-orders-edit-view mobile-layout'
		template: JST['office/templates/company/orders']

		behaviors:
			Epoxy: {}
			Layout:
				outlets:
					officeTopbar: JST['office/templates/office-topbar']
			Form:
				submit: '[name=save-button]'
				events:
					click: '[name=save-button]'

		validated: ->
			model: @model

		serializeData: ->
			_.extend @model.toJSON(), company: @options.company

		initialize: =>
			@model = new Iconto.REST.Company @options.company
			@buffer = new Iconto.REST.Company @options.company

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
#				topbarTitle: 'Заказы'
#				topbarSubtitle: 'Настройки заказа'
#				tabs: [
#					{title: 'Товары', href: "office/#{@options.companyId}/shop"}
#					{title: 'Заказы', href: "office/#{@options.companyId}/shop/orders"}
#					{title: 'Настройки', href: "office/#{@options.companyId}/shop/orders/edit", active: true}
#				]
				breadcrumbs: [
					{title: 'Профиль', href: "office/#{@options.companyId}/profile"}
					{title: 'Настройки профиля компании', href: "#"}
				]
				officeTopbar:
					currentPage: 'orders'

				topbarTitle: 'Редактирование компании'
				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal,
					leadingComma: true)}"

				isLoading: false

				categories: []

		onFormSubmit: =>
			fields = (new Iconto.REST.Company(@buffer.toJSON())).set(@model.toJSON()).changed

			unless _.isEmpty fields
				@model.save(fields)
				.then =>
					route = "/office/#{@options.companyId}/profile"
					Iconto.office.router.navigate route, trigger: true
				.dispatch(@)
				.catch (error) =>
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()