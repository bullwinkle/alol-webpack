@Iconto.module 'office.views.company', (Company) ->
	class AddressItemView extends Marionette.ItemView
		template: JST['office/templates/company/addresses/address-item']
		className: 'button list-item menu-item'
		tagName: 'a'
		attributes: ->
			href: "/office/#{@model.get('company_id')}/addresses/#{@model.get('id')}"

	class Company.AddressesView extends Marionette.CompositeView
		template: JST['office/templates/company/addresses/addresses']
		className: 'office-addresses-view mobile-layout'
		childView: AddressItemView
		childViewContainer: '.addresses'

		behaviors:
			Epoxy: {}
			Layout:
				outlets:
					officeTopbar: JST['office/templates/office-topbar']

		serializeData: =>
			_.extend @model.toJSON(), company: @options.company

		initialize: =>
			@model = new Backbone.Model()
			@collection = new Iconto.REST.AddressCollection()

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Адреса'
				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal,
					leadingComma: true)}"
				isLoading: false
				breadcrumbs: [
					{title: 'Профиль', href: "office/#{@options.companyId}/profile"}
					{title: 'Настройки профиля компании', href: "#"}
				]
				officeTopbar:
					currentPage: 'addresses'

		onAttach: =>
			@collection.fetchAll(company_id: @options.company.id)
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()