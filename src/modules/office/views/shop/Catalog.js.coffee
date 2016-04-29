@Iconto.module 'office.views.shop', (Shop) ->
	inherit = Iconto.shared.helpers.inherit

	# rewrites of Shop module
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


	class Shop.ShopCategoryEmptyView extends Iconto.order.views.ShopCategoryEmptyView


	class Shop.ShopCartEmptyView extends Iconto.order.views.ShopCartEmptyView


	class Shop.ShopSearchEmptyView extends Iconto.order.views.ShopSearchEmptyView


	class ProductState extends Backbone.Model
		defaults:
			editing: false


	class Shop.ShopCategoryItemView extends Iconto.order.views.ShopCategoryItemView
		initialize: ->
			companyId = _.get(@,'options.catalogOptions.company_id',0)
			addressId = _.get(@,'options.catalogOptions.address_id',0)
			categoryId = _.invoke([@],'model.get','id')[0] || 0
			productId = _.get(@,'options.catalogOptions.product_id',0)
			queryParams = _.get(@,'options.catalogOptions.queryParams','')

			href = ""
			href += "/office/#{	companyId }" if companyId
			# href += "/address/#{ addressId }" if addressId
			href += "/shop/category/#{ categoryId }" if categoryId
			# href += "/product/#{ productId }" if productId
			href += queryParams if queryParams
			@model.set 'href', href

		onElClick: (e) => @handle e, (e) => super(e)


	class Shop.ShopProductItemView extends Iconto.order.views.ShopProductItemView
		template: JST['office/templates/shop/catalog/shop-product']

		className: "shop-product-item s-noselect"

		ui: inherit Iconto.order.views.ShopProductItemView::ui,
			'form': 'form'
			'editButton': '.edit'
			'deleteButton': '.delete'
			'cancelButton': '.cancel'
			'submitButton': '[type=submit]'
			'categorySelect': 'select[name=shop_category_id]'
			'uploadFile':'.file-upload'
			'fileInput':'[name=file]'
			'filesNames': '.files-names'
			'image': '.product-icon .image'
			'deleteImageButton': '.delete-image'
			'virtualSelect': '.ui-virtual-select'

		events: inherit Iconto.order.views.ShopProductItemView::events,
			'click @ui.editButton': 'onEditButtonClick'
			'click @ui.cancelButton': 'onCancelButtonClick'
			'click @ui.deleteButton': 'onDeleteButtonCLick'
			'click @ui.uploadFile' : 'onUploadFileClick'
			'change @ui.fileInput' : 'onFileInutChange'
			'click @ui.deleteImageButton': 'onDeleteImageButtonClick'
			'click @ui.submitButton': 'onFormSubmit'

		bindings: inherit Iconto.order.views.ShopProductItemView::bindings,
			"[data-showing]":  			"classes:{hide: state_editing}"
			"[data-editing]":  			"classes:{hide: not(state_editing)}"
			"[data-title-input]": "value: title"
			"[data-description-input]": "value: description"
			"[data-price-input]": "value: price"
			"[data-shop-category]": "value: number(shop_category_id)"

#		behaviors: inherit Iconto.order.views.ShopProductItemView::behaviors
#			Form:
#				validated: ['model']
#				submit: 'form'
#				events:
#					submit: 'form'

		initialize: (options) ->
			console.log 'Shop.ShopProductItemView', @options

			@model.set
				headHref: @getLinkToBack()
				headTitle: @model.get('title')
			@buffer = new Iconto.REST.ShopGood @model.toJSON()

			@clearState()
			@listenTo @state,
				'change:editing': @onEditingChange


			@listenTo @model,
				'change:image': (model, url, options) =>
					unless url then url = '/static/images/original/default.jpg'
					@ui.image.css 'background-image', "url('#{url}')"

			@categoryDataProvider = new CategoryDataProvider()

		getLinkToBack: =>
			href = ""
			href += "/wallet/company/#{	@options.catalogOptions.company_id }" if @options.catalogOptions.company_id
			href += "/address/#{		@options.catalogOptions.address_id }" if @options.catalogOptions.address_id
			href += "/shop/category/#{	@options.parentCategoryId }"		  if @options.parentCategoryId
			href += "#{if !@options.parentCategoryId then '/shop' else ''}/product/#{ @options.model.get('id')}" if @options.model.get('id')
			href += decodeURIComponent(Url.format({query:  @options.catalogOptions.queryParams }))if @options.catalogOptions.queryParams
			href

		onElClick: (e) => @handle e, (e) =>
#			@state.set 'editing', !@state.get('editing')
#			@ui.categorySelect.selectOrDie()

		productInCart: => false


		onEditButtonClick: (e) => @handle e, (e) =>
			@state.set 'editing', !@state.get('editing')

			@ui.virtualSelect.virtualselect
				dataProvider: new CategoryDataProvider()
				onSelect: @onSelect

		onSelect: (item) =>
			@model.set('shop_category_id',item.id)

		onEditingChange: (model, editing, options) =>
			@$el["#{if editing then "add" else "remove"}Class"] 'editing'

		onDeleteButtonCLick:  (e) => @handle e, =>
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

		onCancelButtonClick: (e) => @handle e, =>
			@model.set @buffer.toJSON()
			@state.set 'editing', false

		onUploadFileClick: (e) => @handle e, =>
			@ui.fileInput.click()

		onFileInutChange: (e) =>
			files = e.target.files
			filesNames = _.pluck(files, 'name')
			@ui.filesNames.text filesNames.join ', '
			Iconto.shared.services.file.upload files[0]
			.then (res) =>
				if res.url
					@model.set 'image_id', res.id
					@model.set 'image_url', res.url, silent: true # fake url
					@ui.image.css 'background-image', "url('#{res.url}')"
			.catch (err) =>
				console.error err
			.done =>
				@ui.fileInput[0].value = ''

		onFormSubmit: =>
			return false if @submitBlocked
			@submitBlocked = true

			changed = @buffer.set(@model.toJSON()).changed
			return false if _.isEmpty changed

			@ui.submitButton.addClass 'is-loading'
			unless changed.shop_category_id
				@updateProduct changed, =>
#					delete @submitBlocked
#					@ui.submitButton.removeClass 'is-loading'
#					@clearState()
#					@render()
			else
				Iconto.shared.views.modals.Confirm.show
					title: "Смена категории товара"
					message: "Вы уверены, что хотите перенести товар в другую категорию?"
					onSubmit: =>
						@updateProduct changed, =>
							delete @submitBlocked
							@ui.submitButton.removeClass 'is-loading'

							# TODO the product must be force pushed to new category because it wiill not update if already got more then 10 goods
							@model.collection.remove @model

		updateProduct: (properties={}, callback=->) =>
			return callback() if _.isEmpty properties
			@model.save( properties )
			.then callback
			.catch (err) =>
				console.error
				@ui.submitButton.removeClass 'is-loading'
				@submitBlocked = false
				Iconto.shared.views.modals.Alert.show
					title: 'Произошла ошибка'
					message: 'Попробуйте еще раз'

		clearState: =>
			@state.set
				'editing': false

		onDeleteImageButtonClick: (e) => @handle e, =>
			@model.set 'image_id', 0
			@model.set 'image_url', ''
			@ui.filesNames.text('')

		onProductPreviewClick: (e) => @handle e, =>
			if @state.get('editing')
				@ui.fileInput.click()
			else
				src = @model.get('image') || @model.get('image_url')
				Iconto.shared.views.modals.LightBox.show
					img: src


	class Shop.ShopCategoryView extends Iconto.order.views.ShopCategoryView

		initialize: ->
			console.log 'Shop.ShopCategoryView', @options
			super

			@options.cache = false

		getTemplate: =>
			if @options.root
				JST['order/templates/shop/shop-category-root']
			else
				JST['order/templates/shop/shop-category']

		getChildView: (model) =>
			switch model.get 'type'
				when Iconto.REST.ShopGood.TYPE
					Shop.ShopProductItemView
				when Iconto.REST.ShopCategory.TYPE
					Shop.ShopCategoryItemView

		getQuery: =>
			query = {}
			query.company_id = @catalogOptions.company_id
			unless @options.root and @model
				query.category_id = @model.get('id')
			query

		getLinkToBack: =>
			companyId = _.get(@,'options.catalogOptions.company_id',0)
			"/office/#{companyId}/shop"


	class Shop.ShopSearchView extends Iconto.order.views.ShopSearchView
		getChildView: -> Shop.ShopProductItemView
		getEmptyView: -> Shop.ShopSearchEmptyView


	class Shop.ShopCatalogLayout extends Iconto.order.views.ShopCatalogLayout
		initialize: ->
			console.log 'Shop.ShopCatalogLayout', @options
			super
		showCategories: =>
			Q.fcall =>
				view = new Shop.ShopCategoryView
					model: null
					catalogOptions: @options.catalogOptions
					root:true

				@listenTo view,
					'category:click': @showCategory
					'product:click': @showProduct

				@categoriesRegion.show view

		showCategory: (categoryModel) =>
			view = new Shop.ShopCategoryView
				model: categoryModel
				catalogOptions: @options.catalogOptions
				root: false

			@listenTo view,
				'category:click': @showCategory
				'product:click': @showProduct

			@addCategoryRegion()
			.then (region) =>
				region.show view


	class Shop.GoodsView extends Iconto.order.views.ShopLayout
		showedIn: 'back-office' # 'front'
		template: JST['office/templates/shop/catalog/shop-layout']

		regions:
			catalogRegion: '#catalog-region .shop-catalog-region'

		initialize: ->
			globalOptions =
				companyId: @options.companyId

			stateNames = [
				'catalog'
				'search'
				'checkout'
			]

			@state = new Iconto.shared.models.BaseStateViewModel _.extend {}, @options,
				stateName: 'catalog'
				topbarTitle: ''
				topbarSubtitle: ''
				topbarRightButtonSpanClass: 'ic-pencil-square'
				isLoading: false
				tabs: [
					{title: 'Товары', href: "office/#{@options.companyId}/shop", active: true}
					{title: 'Заказы', href: "office/#{@options.companyId}/shop/orders"}
					{title: 'Настройки', href: "office/#{@options.companyId}/shop/orders/edit"}
					{title: 'Добавить транзакцию', href: "/office/#{@options.companyId}/add-transaction"}
				]

		onRender: =>
			@loadDeps()
			.then @showCatalog
			.then =>
				@state.set 'isLoading',false

		showCatalog: =>
			Q.fcall =>
				view = new Shop.ShopCatalogLayout
					parentView: @
					cartCollection: @cartCollection
					catalogOptions:
						company_id: @options.companyId
				@catalogRegion.show view

		onTopbarRightButtonClick: =>
			Iconto.office.router.navigate "/office/#{@options.companyId}/shop/edit", trigger: true

		goBack: =>
			defaultRoute = "/wallet/cards"
			parsedUrl = Iconto.shared.helpers.navigation.parseUri()
			fromRoute = _.get parsedUrl, 'query.from'
			route = fromRoute or defaultRoute
			Iconto.shared.router.navigate route, trigger: true

		onCartCollectionChange: => return false
		showCheckout: => return false

