@Iconto.module 'office.views.company', (Company) ->
	class Company.DocumentsView extends Marionette.ItemView
		template: JST['office/templates/company/documents']
		className: 'documents-view mobile-layout'

		events:
			'click .topbar-region .left-small': 'onTopbarLeftButtonClick'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		initialize: =>
			@model = new Backbone.Model()

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Документы'
				isLoading: false
#				breadcrumbs: [
#					{title: 'Компания', href: "office/#{@options.companyId}/profile"}
#					{title: 'Документы', href: "#"}
#				]