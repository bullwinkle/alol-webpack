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



	class GoodView extends Marionette.ItemView
		template: JST['office/templates/shop/edit/goods/good']
		tagName: 'li'
		className: 'good'

		behaviors:
			Epoxy: {}
			Form:
				submit: '[name=save-good-button]'
				events:
					click: '[name=save-good-button]'

		validated: ->
			model: @model

		ui:
			goodInput: '.good-input-inner'
			cancelButton: '[name=cancel-button]'
			categorySelect: '[name=shop_category_id2]'

			deleteButton: '.delete-image-button'
			uploadButton: '.g-image-src'
			uploadInput: 'input[type=file]'
			head: '.button'
			virtualSelect: '.ui-virtual-select'

		events:
			'click .ic-cross-circle': 'onDeleteClick'
			'click @ui.head': 'onEditClick'
			'click @ui.cancelButton': 'onCancelClick'

			'click @ui.uploadButton': 'onUploadButtonClick'
			'change @ui.uploadInput': 'onUploadInputChange'
			'click @ui.deleteButton': 'onDeleteButtonClick'
			'click input, button' : (e) -> e.stopPropagation()

		initialize: =>
			@buffer = new Iconto.REST.ShopGood @model.toJSON()
			@state = new Backbone.Model shopCategories: @options.categories

		onDeleteClick: (e) =>
			e.stopPropagation()
			Iconto.shared.views.modals.Confirm.show
				title: 'Удаление товара'
				message: 'Вы уверены, что хотите удалить товар?'
				onSubmit: =>
					@model.destroy()
					.dispatch(@)
					.catch (error) ->
						console.error error
						Iconto.shared.views.modals.ErrorAlert.show error
					.done()

		onShow: =>
			@model.trigger 'change:shop_category_id'

		onEditClick: (e) =>
			e.stopPropagation()
			@$el.toggleClass('open')

			@ui.virtualSelect.virtualselect
				dataProvider: new CategoryDataProvider()
				onSelect: @onSelect

		onSelect: (item) =>
			@model.set('shop_category_id',item.id)

		onCancelClick: (e) =>
			e.stopPropagation()
			@$el.toggleClass('open')

		onFormSubmit: =>
			fields = (new Iconto.REST.ShopGood(@buffer.toJSON())).set(@model.toJSON()).changed

			unless _.isEmpty fields
				@model.save(fields)
				.then =>
					@$el.removeClass('open')
				.dispatch(@)
				.catch (error) ->
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()

		onDeleteButtonClick: =>
			@model.set
				image_id: 0
				image_url: Iconto.REST.ShopGood::defaults.image_url
				image: Iconto.REST.ShopGood::defaults.image

		onUploadButtonClick: (e) =>
			e.stopPropagation()
			@ui.uploadInput.click()

		onUploadInputChange: (e) =>
			e.stopPropagation()
			@uploadImage @ui.uploadInput.prop("files")[0]

		uploadImage: (file) =>
			fileService = Iconto.shared.services.file
			fileService.upload(file)
			.then (@response) =>
				@model.set
					image_id: @response.id
					image_url: @response.url
					image: @response.url
			.dispatch(@)
			.catch (error) ->
				console.error error
				error.msg = switch (error.status)
					when 400777 then 'Размер файла не должен превышать 1 МБ.'
					else
						error.msg
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@ui.uploadInput[0].value = ''

	class Shop.EditGoodsView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView

		template: JST['office/templates/shop/edit/goods/goods']
		className: 'shop-edit-goods-view mobile-layout'
		childView: GoodView
		childViewContainer: '.menu-items'

		behaviors:
			Epoxy: {}
			Form:
				submit: '[type=submit]'
				events:
					submit: 'form'
				validated: ['model']

			InfiniteScroll:
				offset: 2500
				scrollable: '.view-content'

			Layout:
				outlets:
					shopTopbar: JST['office/templates/shop/shop-topbar']

		serializeData: ->
			_.extend @model.toJSON(), company: @options.company

		childViewOptions: =>
			categories: @state.get('shopCategories')

		ui:
			addGood: '.add-good'
			goodInput: '.good-input'
			categorySelect: '[name=shop_category_id2]'
			cancelButton: '[name=cancel-button]'

			goodImage: '.g-image'
			deleteButton: '.delete-image-button'
			uploadButton: '.g-image-src'
			uploadInput: 'input[type=file]'
			'virtualSelect': '.ui-virtual-select'

		events:
			'click @ui.addGood': 'onAddGoodClick'
			'click @ui.uploadButton': 'onUploadButtonClick'
			'change @ui.uploadInput': 'onUploadInputChange'
			'click @ui.deleteButton': 'onDeleteButtonClick'
			'click @ui.cancelButton': 'onAddGoodClick'

		initialize: =>
			globalOptions.companyId = @options.companyId
			@model = new Iconto.REST.ShopGood
				company_id: @options.companyId

			@collection = new Iconto.REST.ShopGoodCollection()

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Товары и услуги'
				topbarSubtitle: 'Редактирование товаров и услуг'
				topbarRightButtonSpanClass: ''
				shopTopbar:
					currentPage: 'edit'
				isLoading: true
				isAddingGood: false
				loadMorePrevented: false
				breadcrumbs: [
					{title: 'Заказы', href: "office/#{@options.companyId}/shop"}
					{title: 'Редактирование товаров и услуг', href: "#"}
				]

				shopCategories: []

		getQuery: =>
			query =
				company_id: @options.companyId

		reload: =>
			@$el.addClass 'is-loading'
			@infiniteScrollState.set
				offset: 0
				complete: false
			_.defer =>
				@preload()
				.dispatch(@)
				.catch (error) ->
					console.error error
				.done =>
					@$el.removeClass 'is-loading'

		_loadMore: =>
			if @state.get 'loadMorePrevented'
				Q.fcall => true
			else
				super()

		onRender: =>
			(new Iconto.REST.ShopCategoryCollection()).fetch(company_id: @options.companyId, limit: 5000)
			.then (categories) =>

				# set parent_id = 0 where null
				_.each categories, (category) ->
					category.parent_id ||= 0

				# group categories by parent_id
#				groupedCategories = _.groupBy categories, (category) ->
#					category.parent_id
#
#				# sort top categories by name
#				groupedCategories["0"] = _.sortBy groupedCategories["0"], (item) ->
#					item.title
#
#				finalArray = []
#
#				_.each groupedCategories["0"], (c) ->
#					toPush =
#						category: c
#						subcategories: _.sortBy groupedCategories["#{c.id}"], (item) -> item.title
#					finalArray.push toPush
				finalArray = Iconto.shared.helpers.makeCategoriesTree categories, 'parent_id', 'id', 'subcategories'
				@state.set
					isLoading: false
					shopCategories: finalArray

				#@ui.categorySelect.selectOrDie()
#				@ui.categorySelect.change()

				@reload()

			.dispatch(@)
			.catch (error) =>
				console.log error
			.done()

		onAddGoodClick: =>
			value = !@state.get('isAddingGood')
			@state.set
				isAddingGood: value
				loadMorePrevented: value

			@ui.virtualSelect.virtualselect
				dataProvider: new CategoryDataProvider()
				onSelect: @onSelect

		onSelect: (item) =>
			@model.set('shop_category_id',item.id)

		onFormSubmit: =>
			console.warn 'onFormSubmit'
			fields = @model.pick 'title', 'shop_category_id', 'company_id', 'image_id', 'description', 'price'
			@model.set id: 0

			@model.save(fields)
			.then =>
				shopCategoryId = 0
				shopCategories = @state.get('shopCategories')
				if shopCategories[0].subcategories.length is 0
					shopCategoryId = shopCategories[0].category.id
				else
					shopCategoryId = shopCategories[0].subcategories[0].id

				@collection.unshift new Iconto.REST.ShopGood @model.toJSON()
				@model.set (new Iconto.REST.ShopGood(company_id: @options.companyId, shop_category_id: shopCategoryId)).toJSON(),
					validate: false
			.dispatch(@)
			.catch (error) ->
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				value = !@state.get('isAddingGood')
				@state.set
					isAddingGood: value
					loadMorePrevented: value

		onDeleteButtonClick: =>
			if @model.get('image_id')
				@model.set
					image_id: 0
					image_url: Iconto.REST.ShopGood::defaults.image_url

		onUploadButtonClick: (e) =>
			@ui.uploadInput.click()

		onUploadInputChange: =>
			@uploadImage @ui.uploadInput.prop("files")[0]

		uploadImage: (file) =>
			fileService = Iconto.shared.services.file
			fileService.read(file)
			.then (e) =>
				fileService.upload(file)
				.then (@response) =>
					@model.set
						image_id: @response.id
						image_url: @response.url
			.dispatch(@)
			.catch (error) ->
				console.error error
				error.msg = switch (error.status)
					when 400777 then 'Размер файла не должен превышать 1 МБ.'
					else
						error.msg
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@ui.uploadInput[0].value = ''