@Iconto.module 'office.views.shop', (Shop) ->
	class Shop.OrdersEditView extends Marionette.ItemView
		className: 'shop-orders-edit-view mobile-layout'
		template: JST['office/templates/shop/edit/orders/orders']

		behaviors:
			Epoxy: {}
			Layout: {}
			Form:
				submit: 'form'
				events:
					click: '[name=save-button]'

		validated: ->
			model: @model

		initialize: =>
			@model = new Iconto.REST.Company @options.company
			@buffer = new Iconto.REST.Company @options.company

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
#				topbarTitle: 'Заказы'
#				topbarSubtitle: 'Настройки заказа'
				topbarTitle: ''
				topbarSubtitle: ''
				isLoading: false
				isSaving: false
				tabs: [
					{title: 'Товары', href: "office/#{@options.companyId}/shop"}
					{title: 'Заказы', href: "office/#{@options.companyId}/shop/orders"}
					{title: 'Настройки', href: "office/#{@options.companyId}/shop/orders/edit", active: true}
					{title: 'Добавить транзакцию', href: "/office/#{@options.companyId}/add-transaction"}
				]
#				breadcrumbs: [
#					{title: 'Заказы', href: "office/#{@options.companyId}/shop/orders"}
#					{title: 'Настройки заказа', href: "#"}
#				]

		onFormSubmit: =>
			return false if @state.get('isSaving')

			fields = (new Iconto.REST.Company(@buffer.toJSON())).set(@model.toJSON()).changed
			return false if _.isEmpty fields

			@state.set('isSaving', true)

			if fields.order_form_url
				fields.order_form_url = Iconto.shared.helpers.navigation.parseUri(fields.order_form_url).href

			@model.save(fields)
			.then (company) =>
				@buffer = new Iconto.REST.Company company
				alertify.success 'Настойки успешно сохранены'
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set('isSaving', false)