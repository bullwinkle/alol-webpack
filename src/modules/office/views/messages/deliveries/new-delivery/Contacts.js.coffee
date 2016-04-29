#= require office/views/customers/Customers

@Iconto.module 'office.views.messages.deliveries.new', (New) ->
	class New.ContactItemView extends Iconto.office.views.customers.CustomerItemView
		onRender: =>
			if @model.get('id') in @options.selected
				@$('button').addClass 'active'

	class New.ContactsView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView #Marionette.CompositeView
		className: 'contacts-view mobile-layout'
		template: JST['office/templates/messages/deliveries/new-delivery/contacts']
		childView: New.ContactItemView
		childViewContainer: '.list'

		behaviors:
			Epoxy: {}
			Layout: {}
			InfiniteScroll:
				scrollable: '.list-wrap'

		ui:
			cancelButton: '[name=cancel]'
			submitButton: '[name=submit]'
			query: 'input[name=query]'

		triggers:
			'click @ui.cancelButton': 'transition:back'

		events:
			'click @ui.submitButton': 'onSubmitButtonClick'

		bindingSources: =>
			infiniteScrollState: @infiniteScrollState

		childViewOptions: =>
			selected: @state.get('selected')

		initialize: =>
			@model = @options.model
			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Выбор контактов'
				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal,
					leadingComma: true)}"
				isLoading: false
				breadcrumbs: [
					{title: 'Рассылки', href: "/office/#{@options.companyId}/messages/deliveries"},
					{title: 'Создание рассылки', href: "/office/#{@options.companyId}/messages/delivery/new"}
				]

				query: ''
				amount_all: 0
				selected: @model.get('customer_filter_ids')

			@listenTo @state,
				'change:query', _.debounce(@reload, 300)

			@collection = new Iconto.REST.CompanyClientCollection()

		getQuery: =>
			data = company_id: @options.companyId
			query = @state.get('query')
			data.query = query if query
			data

		onRender: =>
			allPromise = @collection.count(company_id: @options.company.id)
			.then (totalAmount) =>
				@state.set amount_all: totalAmount
			contactsPromise = @preload()

			Q.all([allPromise, contactsPromise])
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onChildviewClick: (childView, itemModel) =>
			$button = childView.$('button').toggleClass 'active'
			selected = @state.get('selected').slice()
			if $button.hasClass 'active'
				selected.push itemModel.get 'id'
			else
				selected.splice selected.lastIndexOf itemModel.get('id'), 1
			@state.set selected: selected

		onSubmitButtonClick: =>
			@model.set customer_filter_ids: @state.get('selected')
			@trigger 'transition:back'