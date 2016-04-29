@Iconto.module 'office.views.index', (Index) ->
	class CompanyView extends Marionette.ItemView
		template: JST['office/templates/index/company']
		className: 'panel'
		attributes: =>
			'data-id': @model.get('id')

		events:
			'click': 'onClick'

		initialize: =>
			@model.set
				image_id: @model.get('image').id || 0
				legalName: Iconto.shared.helpers.legal.getLegal(@model.get('legal'))
				depositAmount: Iconto.shared.helpers.money @model.get('deposit').amount

		onClick: =>
			url = "/office/#{@model.get('id')}"
			url = "#{url}/profile" unless @model.get('is_active')
			Iconto.office.router.navigate url, trigger: true

	class EmptyCompaniesView extends Marionette.ItemView
		template: JST['office/templates/index/empty-companies']
		className: 'welcome-view'

	class Index.CompaniesView extends Marionette.CompositeView
		template: JST['office/templates/index/companies']
		className: 'companies-view mobile-layout'
		childView: CompanyView
		childViewContainer: '.list-items'
		emptyView: EmptyCompaniesView

		behaviors:
			Epoxy: {}
			Layout: {}

		ui:
			topbarRightButton: '.topbar-region .right-small'

		events:
			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'

		initialize: =>
			@model = new Backbone.Model(query: '')
			@collection = new Iconto.REST.CompanyCollection()

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Компании'
				topbarRightButtonSpanClass: 'ic-plus-circle'
				showSearch: false

			# search companies by name
			@listenTo @model, 'change:query', _.debounce @onSearch, 0

			# enable fullscreen
			Iconto.commands.execute 'workspace:fullscreen:enable'

		onTopbarRightButtonClick: =>
			Iconto.office.router.navigate "/office/new", trigger: true

		onRender: =>
			# Company comparator
			# group by is_active and sort by name
			@collection.comparator = (model1, model2) ->
				if model1.get('is_active') and model2.get('is_active')
					if model1.get('name') > model2.get('name')
						return 1
					else
						return -1
				else
					if model1.get('is_active')
						return -1
					if model2.get('is_active')
						return 1
					if not model1.get('is_active') and not model2.get('is_active')
						if model1.get('name') > model2.get('name')
							return 1
						else
							return -1

			# get my companies ids
			(new Iconto.REST.CompanyCollection()).fetchIds(filters: ['my'])
			.then (companyIds) =>

				# get my companies
				(new Iconto.REST.CompanyCollection()).fetchByIds(companyIds, {reload: true})

			.then (companies) =>

				# filter deleted companies if any
				companies = _.filter companies, (company) ->
					!company.deleted and company.is_active

				# pluck catgory ids
				categoryIds = _.unique _.compact _.pluck companies, 'category_id'

				# categories promise
				categoriesPromise = (new Iconto.REST.CompanyCategoryCollection()).fetchByIds(categoryIds)

				# pluck legal ids for deposits
				legalIds = _.unique _.compact _.pluck companies, 'legal_id'

				# get legals
				(new Iconto.REST.LegalEntityCollection()).fetchByIds(legalIds)
				.then (legals) =>

					# pluck deposit ids
					depositIds = _.unique _.compact _.pluck legals, 'deposit_id'

					# get deposits, must reload every time
					depositsPromise = (new Iconto.REST.DepositCollection()).fetchByIds(depositIds, {reload: true})

					# wait for categories and deposits
					Q.all([categoriesPromise, depositsPromise])
					.then ([categories, deposits]) =>

						# populate companies with legal, deposit and category
						_.each companies, (model) =>

							# find legal
							model.legal = _.find legals, (item) =>
								item.id is model.legal_id
							model.legal ||= new Iconto.REST.LegalEntity().toJSON()

							# find deposit
							model.deposit = _.find deposits, (item) =>
								item.id is model.legal.deposit_id
							model.deposit ||= new Iconto.REST.Deposit().toJSON()

							# find category
							model.category = _.find categories, (item) =>
								item.id is model.category_id
							model.category ||= new Iconto.REST.CompanyCategory().toJSON()

						# reset collection with populated models
						@collection.reset companies

						# show view and search string
						@state.set
							isLoading: false
							showSearch: companies.length > 20

			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onSearch: (model, value) =>
			@$(".list-items [data-id]").removeClass('hide')
			@collection.each (model) =>
				if model.get('name').toLowerCase().indexOf(value.toLowerCase()) < 0
					@$("[data-id=#{model.get('id')}]").addClass('hide')

		onBeforeDestroy: =>
			Iconto.commands.execute 'workspace:fullscreen:disable'