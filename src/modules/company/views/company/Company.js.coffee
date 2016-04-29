@Iconto.module 'company.views', (Views) ->
	class Views.CompanyView extends Marionette.ItemView
		className: 'company-view mobile-layout'
		template: JST['company/templates/company/company']

		behaviors:
			Epoxy: {}
			Layout: {}

		ui:
			showAddressesButton: ".show-all-addresses-on-map"
			addressItem: ".address-item"
			topbarLeftButton: '.topbar-region .left-small'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
			'click @ui.showAddressesButton': "onShowAddressesButtonClick"
			'click @ui.addressItem': "onAddressItemClick"

		initialize: ->
			@model = new Iconto.REST.Company
				id: @options.companyId
				site_href: ''

			@state = new Iconto.company.models.StateViewModel _.extend {}, @options,
				topbarLeftButtonClass: ''
				topbarLeftButtonSpanClass: 'ic-chevron-left'
				categoryName: ''
				addresses_count: 0
				site_href: ''
				addresses: []

		onRender: ->
			(new Iconto.REST.AddressCollection()).fetchAll(company_id: @options.companyId)
			.then (addresses) =>
				@state.set addresses: addresses
			.dispatch(@)
			.catch (error) ->
				console.error error

			@model.fetch(null, {reload: true})
			.then (model) =>
				@state.set site_href: Iconto.shared.helpers.navigation.parseUri(model.site).href
				model.image_url = @model.get('image').url
				model.site = Iconto.shared.helpers.toUnicode(@model.get('site'))
				@model.set model

				(new Iconto.REST.CompanyCategory(id: model.category_id)).fetch()
			.then (category) =>
				@state.set
					isLoading: false
					categoryName: category.name
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error

		onShowAddressesButtonClick: (e) =>
			console.log $(e.currentTarget).data()

		onTopbarLeftButtonClick: =>
			defaultRoute="/wallet/cards"
			queryRouteParam='query.from'
			navigateOptions = trigger:true
			Iconto.shared.helpers.navigation.navigateBack(defaultRoute, queryRouteParam, navigateOptions)

#		onAddressItemClick: (e) =>
#			data = $(e.currentTarget).data()
#
#			ViewClass = Iconto.wallet.views.Map
#			App.workspace.currentView.slideableRegionRight.show new ViewClass data
