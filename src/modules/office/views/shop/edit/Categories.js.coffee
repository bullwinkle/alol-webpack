@Iconto.module 'office.views.shop', (Shop) ->
	globalOptions = {}
	class CategoryDataProvider extends Iconto.shared.services.VirtualScrollDataProvider

		load: =>
			query =
				limit: 5000
				company_id: globalOptions.companyId

			(new Iconto.REST.ShopCategoryCollection()).fetch query
			.then (items) =>
				@items = items
				@availableItems = items

		filter : (search) =>
			if search.length > 0
				@items = _.filter(@availableItems, (item) ->
					item.title.indexOf(search) == 0
				)
			else
				@items = @availableItems
			return

		displayText: (item, extended) =>
			if item
				if extended then item.title + ' (' + item.id + ')' else item.title
			else
				''
		noSelectionText : =>
			'Выберите родительскую категорию'



	class CategoryView extends Marionette.CompositeView
		tagName: 'li'
		template: JST['office/templates/shop/edit/categories/category']
		className: 'category open'
		childView: CategoryView
		childViewContainer: '.subcategories .menu-items'
		attributes:
			draggable: false

		behaviors:
			Epoxy: {}
			Form:
				submit: 'form'
				events:
					submit: 'form'
				validated: ['model']

		ui:
			form: 'form'
			title: '.title'
			titleInput: '[name=title]'
			parentCategorySelect: '[name=parent_id]'
			head: '.list-item'
			cancelButton:"[name=cancel-button]"
			submitButton:"[type=submit]"
			'virtualSelect': '.ui-virtual-select'

		events: ->
			events =
				'click .ic-cross-circle': 'onDeleteClick'
				'click @ui.head': 'onEditClick'
				'input @ui.titleInput': 'onTitleInputChange'
				'paste @ui.titleInput': 'onTitleInputChange'
				'change @ui.titleInput': 'onTitleInputChange'
				'change @ui.parentCategorySelect': 'onParentCategorySelectChange'
				'click @ui.cancelButton': 'onCancelClick'
				'click input, button': (e) -> e.stopPropagation()
			if _.get(@,'attributes.draggable') then _.extend events,
				'dragstart': 'onDragStart'
				'dragend': 'onDragEnd'
				'dragover': 'onDragover'
				'dragleave': 'onDragleave'
				'drop': 'onDrop'
			events

		childViewOptions: =>
			categories: @options.categories

		initialize: =>
			@state = new Backbone.Model shopCategories: @options.categories
			@collection = new Iconto.REST.ShopCategoryCollection()

		onRender: =>
			@ui.title = @$('.title',@$el).eq(0)
			unless @model.get('children')
				@$('.subcategories').remove()

			setTimeout =>
				if _.get @model.get('children'), 'length'
					_.each @model.get('children'), (item, i) =>
						_.defer =>
							@collection.push item
			,100

		onChildviewUpdated: (view, model) =>
			@trigger 'updated', model

		onChildviewEdit: (view, model) =>
			console.warn 'child onChildviewEdit', arguments
#			@children.each (childView,i) =>
#				return if view is childView
#				_.invoke [childView], 'ui.cancelButton.trigger', 'click'

		onDragStart: (e) =>
			e.stopPropagation()
			console.warn 'onDragStart', @model.get 'id', e.currentTarget
			dataTransfer = e.originalEvent.dataTransfer
			dataTransfer.effectAllowed = ['move']
			dataTransfer.dropEffect = 'move'
			dataTransfer.setData("id", @model.get('id'))

		onDragEnd: (e) =>
			e.preventDefault()
			e.stopPropagation()

		onDragover: (e) =>
			e.preventDefault()
			e.stopPropagation()

		onDragleave: (e) =>
			e.preventDefault()
			e.stopPropagation()

		onDrop: (e) =>
			e.preventDefault()
			e.stopPropagation()
			dataTransfer = e.originalEvent.dataTransfer
			dataId = +dataTransfer.getData("id")
			console.warn 'onDrop', e.currentTarget, dataId,@model.get('id')

		onDeleteClick: (e) =>
			e.stopPropagation()

			Iconto.shared.views.modals.Confirm.show
				title: 'Удаление категории'
				message: 'Вы уверены, что хотите удалить категорию? Все товары в категории будут удалены'
				onSubmit: =>
					@model.destroy({wait: true})
					.then =>
						@model.collection.remove @model
						@$el.remove()
					.dispatch(@)
					.catch (error) =>
						console.error error
						error.msg = switch error.status
							when 200006
								if error.msg is 'Category contained goods'
									'Нельзя удалять категорию, где есть товары'
								else
									'Чтобы удалить категорию, удалите сначала подкатегорию'
							else
								error.msg
						Iconto.shared.views.modals.ErrorAlert.show error
					.done()

		onEditClick: (e) =>
			e.stopPropagation()
			@trigger 'edit',@model
			$('.shop-edit-categories-view .category').removeClass 'edit'
			@$el.addClass 'edit'
			@ui.titleInput.focus()


			@ui.virtualSelect.virtualselect
				dataProvider: new CategoryDataProvider()
				onSelect: @onSelect

		onSelect: (item) =>
			console.log 'selected', item
			@model.set('parent_id',item.id)

		onCancelClick: (e) =>
			e.stopPropagation()
			@$el.removeClass 'edit'

		onTitleInputChange: (e) =>
			val = $(e.currentTarget).val()
			console.log 'onTitleInputChange', val
			@model.set 'title', val

		onParentCategorySelectChange: (e) =>
			val = +$(e.currentTarget).val()
			console.log 'onParentCategorySelectChange', arguments, val
			@model.set 'parent_id', val

		onFormSubmit: (e) =>
			console.log 'onFormSubmit'
			e.preventDefault()
			e.stopPropagation()

			@ui.submitButton.addClass 'is-loading'
			@model.save(@model.pick(['parent_id','title']))
			.then =>
				@ui.title.text @model.get('title')
				@$el.removeClass 'edit'
				# TODO replace with more accurate collection rerender
				@trigger 'updated'
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@ui.submitButton.removeClass 'is-loading'

	class Shop.EditCategoriesView extends Marionette.CompositeView
		template: JST['office/templates/shop/edit/categories/categories']
		className: 'shop-edit-categories-view mobile-layout'
		childView: CategoryView
		childViewContainer: '.menu-items'

		behaviors:
			Epoxy: {}
			Layout:
				outlets:
					shopTopbar: JST['office/templates/shop/shop-topbar']
			Form:
				submit: 'form'
				events:
					submit: 'form'
				validated: ['model']

		ui:
			form: 'form'
			topbarRightButton: '.topbar-region .right-small'
			cancelButton: '[name=cancel-button]'
			addCategory: '.add-category'
			submitButton: '[name=add-category-button]'
			categoryInput: '.category-input'
			categorySelect: '[name=shop_category_id2]'
			categoryTitle: '[name=category-title]'
			'virtualSelect': '.ui-virtual-select'

		events:
			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'
			'click @ui.categoryTitle': 'onCategoryTitleClick'
			'click @ui.addCategory': 'onAddCategoryClick'
			'click @ui.cancelButton': 'onAddCategoryClick'
			'click @ui.submitButton': 'onFormSubmit'

#		bindings:
#			"[data-xbind-category-title]": "value: trim(title), events: ['input','paste','change']"
#			"[data-xbind-parent_id]": "value:integer(parent_id), underscore:state_shopCategories, events: ['change']"

		serializeData: ->
			_.extend @model.toJSON(), company: @options.company

		childViewOptions: =>
			categories: @collection.toJSON()

		initialize: =>
			globalOptions.companyId = @options.companyId
			@model = new Iconto.REST.ShopCategory company_id: @options.company.id
			@collection = new Iconto.REST.ShopCategoryCollection()

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Категории'
				topbarSubtitle: 'Редактирование товаров и услуг'
				topbarRightButtonSpanClass: ''
				shopTopbar:
					currentPage: 'categories'
				isLoading: true
				breadcrumbs: [
					{title: 'Заказы', href: "office/#{@options.companyId}/shop"}
					{title: 'Товары', href: "#"}
				]

				shopCategories: []
				categoryType: 0 # 0 - category, 1 - subcategory

#			@listenTo @collection, 'change add remove', =>
#				@state.set shopCategories: @getShopCategoryArray @collection.toJSON()

		onChildviewUpdated: =>
			console.warn 'model updated'
			@onRender()

		onChildviewEdit: (view, model) =>
			console.warn 'root onChildviewEdit'

		onRender: =>
			(new @collection.constructor()).fetch
				company_id: @options.companyId
				limit:5000
				{silent: true}
			.then (items=[]) =>
				return unless items.length > 0
#				grouped = _.groupBy items, 'parent_id'
#				mainGroup = _.get grouped, '[0]', []
#
#				for group in mainGroup
#					if grouped["#{group.id}"]
#						group.children = grouped["#{group.id}"]
				tree = @getShopCategoryArray(items) || []
				_.defer =>
#						@state.set
#							shopCategories: _.cloneDeep tree
#						@ui.categorySelect.change()
					if tree.length
						_.each tree, (item, i) =>
							_.defer =>
								@collection.add item

			.dispatch(@)
			.catch (error) =>
				console.log error
			.done =>
				@state.set isLoading: false

		getShopCategoryArray: (items=[]) =>
			return [] unless items.length
			# set parent_id = 0 where null
			_.each items, (category) ->
				category.parent_id ||= 0
#
			Iconto.shared.helpers.makeCategoriesTree items, 'parent_id', 'id', 'children'

		onTopbarRightButtonClick: =>
			Iconto.office.router.navigate "/office/#{@options.companyId}/shop/edit", trigger: true

		onAddCategoryClick: =>
			@ui.categoryInput.toggleClass 'hide'

			@ui.virtualSelect.virtualselect
				dataProvider: new CategoryDataProvider()
				onSelect: @onSelect

		onSelect: (item) =>
			console.log item
			@model.set('parent_id',item.id)

		onFormSubmit: (e) =>
			e.preventDefault()

			return false unless @model.isValid(true)

			@ui.submitButton.addClass 'is-loading'

			@model.save(@model.pick('title', 'company_id', 'parent_id'))
			.then =>
				@ui.categoryInput.addClass 'hide'
				@model.set id: 0, title: ''
				@onRender()
			.dispatch(@)
			.catch (error) =>
				error.msg = switch (error.status)
					when 200006 then 'Нельзя добавлять подкатегорию в категорию, где есть товары'
					else
						error.msg
				console.log error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@ui.submitButton.removeClass 'is-loading'