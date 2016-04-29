@Iconto.module 'office.views.company.settings', (Company) ->

	class Company.MessagesSettingsView extends Marionette.LayoutView
		template: JST['office/templates/company/messages/messages']
		className: 'office-settings-messages-layout mobile-layout'

		behaviors:
			Epoxy: {}
			Layout:
				outlets:
					officeTopbar: JST['office/templates/office-topbar']

		regions:
			faqTreeRegion: '.faq-tree-region'

		ui:
			overlay: '.overlay'
			actionSelectButton: '.bottom-large'

		events:
			'click @ui.actionSelectButton': 'onActionSelectButtonClick'
			'click @ui.overlay': 'onOverlayClick'

		modelEvents:{}

		states: [
			'action-select'
		]

		validated: ->
			model: @model

		serializeData: =>
			_.extend @model.toJSON(), company: @options.company

		initialize: =>
			@model = new Backbone.Model()
			@state = new Iconto.shared.models.BaseStateViewModel _.extend {}, @options,
				topbarTitle: 'Адреса'
				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal,
					leadingComma: true)}"
				isLoading: false
				breadcrumbs: [
					{title: 'Профиль', href: "office/#{@options.companyId}/profile"}
					{title: 'Настройки профиля компании', href: "#"}
				]
				officeTopbar:
					currentPage: 'messages'
				isLoading: false
				isLoadingMore: true
				isEmpty: false
				name: ''

		onRender: =>
			faqTreeView = new Iconto.office.views.company.settings.FAQTreeView @options
			@faqTreeRegion.show faqTreeView
			@listenTo faqTreeView, 'faq:ready', =>
				setTimeout =>
					@state.set 'isLoadingMore', false
				, 200

		onOverlayClick: =>
			@state.set 'name', ''

		onActionSelectButtonClick: =>
			@state.set 'name', switch @state.get 'name'
				when 'action-select' then ""
				else 'action-select'