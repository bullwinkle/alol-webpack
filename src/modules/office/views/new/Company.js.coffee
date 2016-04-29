@Iconto.module 'office.views.new', (New) ->
	class New.CompanyView extends Marionette.ItemView
		template: JST['office/templates/new/company']
		className: 'new-company-view mobile-layout'

		behaviors:
			Epoxy: {}
			Layout: {}
			Form:
				submit: '[name=continue-button]'
				events:
					click: '[name=continue-button]'

		ui:
			categorySelect: 'select[name=category_id]'

		serializeData: =>
			@model.toJSON()
			@state.toJSON()

		validated: =>
			model: @model

		initialize: =>
			@model = @options.company
			@buffer = new Iconto.REST.Company @options.company

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Заявка на управление компанией'
				isLoading: false
				categories: {}
				step: 1
				stepIcons: @options.stepIcons

		onRender: =>
			# get company categories
			(new Iconto.REST.CompanyCategoryCollection()).fetchAll()
			.then (categories) =>

				# set parent_id = 0 where null
				_.each categories, (category) ->
					category.parent_id ||= 0

				# group categories by parent_id
				groupedCategories = _.groupBy categories, (category) ->
					category.parent_id

				# sort top categories by name
				groupedCategories["0"] = _.sortBy groupedCategories["0"], (item) ->
					item.name

				groupedNamedCategories = {}

				# fill named categories like {"Auto": [..., ...], "Health": [..., ...]}
				_.each groupedCategories["0"], (item) ->
					groupedNamedCategories[item.name] = _.sortBy groupedCategories["#{item.id}"], (item) ->
						item.name

				# set another to the end
				another = groupedNamedCategories['Другие']
				delete groupedNamedCategories['Другие']
				groupedNamedCategories['Другие'] = another

				@state.set categories: groupedNamedCategories

				if @model.get('category_id')
					# trigger change for epoxy to set select value
					@model.trigger 'change:category_id'
				else
					# set undefined to select nothing
					@model.set category_id: undefined
				@ui.categorySelect.selectOrDie('update')
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onFormSubmit: =>
			@trigger 'transition:addresses'