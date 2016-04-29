@Iconto.module 'order.views', (Views) ->

	class Views.ShopCategoryView extends Iconto.shared.views.infinite.BaseInfiniteCompositeViewNew
		className: ->
			if @options.root
				'shop-category-view'
			else
				'shop-category-view child'

		getTemplate: ->
			if @options.root
				JST['order/templates/shop/shop-category-root']
			else
				JST['order/templates/shop/shop-category']

		getChildView: (model) ->
			switch model.get 'type'
				when Iconto.REST.ShopGood.TYPE then Views.ShopProductItemView
				when Iconto.REST.ShopCategory.TYPE then Views.ShopCategoryItemView

		getEmptyView: -> Views.ShopCategoryEmptyView

		childViewOptions: =>
			catalogOptions: @options.catalogOptions
			renderedIn: 'category'
			parentCategoryId: @model.get('id') or 0

		behaviors: =>
			Epoxy: {}
			InfiniteScroll:
				layout: null
				scrollable: '.list-container'
				offset: 2500

		childViewContainer: '.list'

		ui:
			head: '> .head:eq(0)'

		events:
			'click @ui.head': 'onHeadClick'

		bindingSources: =>
			infiniteScrollState: @infiniteScrollState

		initialize: ->
			@options.cache = true

			@catalogOptions = @options.catalogOptions
			@root = @options.root

			@model ||= new Iconto.REST.ShopCategory()
			@model.set
				headHref: @getLinkToBack()
				headTitle: @model.get('title')

			@collection = new Iconto.REST.ShopCatalogCollection()

			@state = new Iconto.shared.models.BaseStateViewModel @options.catalogOptions
			@state.set isLoading: true

			@infiniteScrollState.set
				limit: 20

			companyId = _.get(@,'options.catalogOptions.company_id',0)
			@cartCollection = new Iconto.shared.services.Cart {companyId}
			@listenTo @cartCollection,
				'add': @onCartCollectionAdd
				'remove': @onCartCollectionRemove
				'reset': @onCartCollectionReset

		onRender: =>
			_.defer @startLoading

		startLoading: =>
			@model.fetch()
			.then =>
				@model.set
					headHref: @getLinkToBack()
					headTitle: @model.get('title')
			.catch (err) =>
				console.warn "#{@model.constructor.name}.fetch faild",err

			@preload()
			.then =>
				@state.set 'isLoading',false
			.catch (err) =>
				console.warn "#{@constructor.name}.preload faild", err

		# VIEW EVENT HANDLERS
		onHeadClick: (e) =>
			@destroy()

		# CHILD VIEW EVENT HANDLERS
		onChildviewRender: (view) =>
			product = view.model
			return unless product
			if @findProductInCart product
				product.set 'inCart', true

		onChildviewCategoryClick: (view,model) =>
			# prevent multyple click on this model`s view
			return false if @onChildviewCategoryClick.blocked
			@onChildviewCategoryClick.blocked = true
			setTimeout =>
				delete @onChildviewCategoryClick.blocked
			, 500
			@trigger 'category:click', model

		onChildviewProductClick: (view,model) =>
			# prevent multyple click on this model`s view
			return false if @onChildviewProductClick.blocked
			@onChildviewProductClick.blocked = true
			setTimeout =>
				delete @onChildviewProductClick.blocked
			, 500
			# trigger click
			@trigger 'product:click', model

		onChildviewProductAddToCart: (view, product) =>
			productInCart = @findProductInCart product
			if productInCart
				productInCart.set
					count: +productInCart.get('count')+1
			else
				unless product.get 'count' then product.set 'count', 1
				@cartCollection.set product.toJSON(), remove: false

			_.defer =>
				_.invoke [@cartCollection],'logger.logProductAdd', productInCart or product

		# CART-COLLECTION EVENT HANDLERS (do not interact with CART here, just with current view)
		onCartCollectionAdd: (product) =>
			currentCollectionProduct = @collection.get product.get('id')
			return unless currentCollectionProduct
			currentCollectionProduct.set
				inCart: true
				count: product.get('count') || 1

		onCartCollectionRemove: (product) =>
			currentCollectionProduct = @collection.get product.get('id')
			return unless currentCollectionProduct
			currentCollectionProduct.set
				inCart: false
				count: 1 # count here need to be 0, because it show actual count of this product in cart at right moment

		onCartCollectionReset: (type, product, cartCollection, options) =>
			@collection.each (product) ->
				product.set
					inCart: false
					count: 1 # count here need to be 0, because it show actual count of this product in cart at right moment

		# VIEW METHODS
		getLinkToBack: =>
			companyId = _.get(@,'options.catalogOptions.company_id',0)
			addressId = _.get(@,'options.catalogOptions.address_id',0)
			parentCategoryId = _.get(@,'options.catalogOptions.prevCategoryId',0)
			productId = _.get(@,'options.catalogOptions.product_id',0)
			queryParams = _.get(@,'options.catalogOptions.queryParams','')
			headHref = ""
			headHref += "/wallet/company/#{ companyId }" if companyId
			headHref += "/address/#{ addressId }" if addressId
			headHref += "/shop"
			headHref += "#{ if parentCategoryId then "/category/#{parentCategoryId}" else '' }"
			# headHref += "/product/#{ productId }" if productId
#			headHref += queryParams if queryParams

			headHref

		getQuery: =>
			query = {}
			query.company_id = @catalogOptions.company_id
			unless @options.root and @model
				query.category_id = @model.get('id')
			query

		findProductInCart: (product) =>
			productId = _.invoke [product], 'get', 'id'
			return @cartCollection.get productId