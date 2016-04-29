@Iconto.module 'office.views.customers', (Customers) ->
	class Customers.CustomerItemView extends Marionette.ItemView
		className: 'customer-item-view'
		template: JST['office/templates/customers/customer-item']

		events:
			'click button': 'onClick'

		behaviors:
			Epoxy: {}

		initialize: ->
			@model.set
				fullName: @model.getName()

			@$el.attr 'data-id', @model.get('id')
			@$el.attr 'data-group-character', @model.get('group_character').toLowerCase()

		onClick: =>
			@trigger 'click', @model

	class Customers.CustomersView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
		className: 'customers-view mobile-layout l-pb-0'
		childView: Customers.CustomerItemView
		childViewContainer: '.list'
		template: JST['office/templates/customers/customers']
		limit: 10

		behaviors:
			Epoxy: {}

			InfiniteScroll:
				scrollable: '.list'

		events:
			'click [name=add-contact]': 'onAddContactClick'
			'click [name=delete-all-contacts]': 'onDeleteAllContactsClick'
			'click [name=upload-contacts]': 'onUploadContactsClick'
			'click .ic-info-circle': 'onClickCircleInfo'


		initialize: (@options) =>
			@state = new Iconto.office.models.StateViewModel @options
			@state.set
#				topbarTitle: 'Клиенты'
#				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal, leadingComma: true)}"
				amount: 0
				query: ''
				showUploadBtn: not Iconto.shared.helpers.device.isIos()

			@state.on 'change:query', _.debounce @reload, 300
			@collection = new Iconto.REST.CompanyClientCollection()

		reload: =>
			@infiniteScrollState.set
				offset: 0
				complete: false
			@collection.reset()
			@preload()
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error

		getQuery: => #used for specifying additional params while fetching
			result =
				company_id: @state.get('companyId')
			query = @state.get('query')
			result.query = query if query
			result

		onRender: =>
			@collection.count(company_id: @options.companyId)
			.done (count) =>
				@state.set
					amount: count
					isLoading: false
			@preload() #defined in BaseInfiniteCompositeView
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()
			setTimeout =>
				$(document).foundation() #for dropdown
			, 500

		onChildviewClick: (childView, itemModel) =>
			Iconto.office.router.navigate "office/#{@state.get('companyId')}/customer/#{itemModel.get('id')}/edit", trigger: true

		onAddContactClick: =>
			Iconto.office.router.navigate "office/#{@state.get('companyId')}/customer/new", trigger: true

		onDeleteAllContactsClick: =>
			Iconto.shared.views.modals.Confirm.show
				title: 'Подтвердите удаление всех клиентов'
				message: 'Отменить данное действие будет невозможно.'
				onSubmit: =>
					@state.set 'isLoading'
					@collection.destroyAll(company_id: @state.get('companyId'))
					.then (response) =>
						@collection.count(company_id: @options.companyId)
						.done (count) =>
							@state.set
								amount: count
						@reload()
						.then =>
							@state.set 'isLoading', false
					.dispatch(@)
					.catch (error) =>
						console.error error
						Iconto.shared.views.modals.ErrorAlert.show error
					.done()

		onUploadContactsClick: =>
			Iconto.office.router.navigate "office/#{@state.get('companyId')}/customers/upload", trigger: true

		onClickCircleInfo: =>
			Iconto.shared.views.modals.Alert.show
				message: "Количество клиентов складывается из тех, что были загружены из файла, добавлены вручную, получены из транзакций, но не включает контакты партнеров."
