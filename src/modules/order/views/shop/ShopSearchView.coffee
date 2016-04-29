@Iconto.module 'order.views', (Views) ->
	inherit = Iconto.shared.helpers.inherit

	class Views.ShopSearchView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
		template: JST['order/templates/shop/shop-search']
		className: 'shop-catalog-search-view'
		getEmptyView: -> Views.ShopSearchEmptyView
		getChildView: -> Views.ShopSearchItemView

		childViewContainer: '.shop-search-result'

		behaviors:
			Layout:
				template: false
			Epoxy: {}
			QueryParamsBinding:
				bindings: [
					model: 'state'
					fields: ['query']
				]
			InfiniteScroll:
				scrollable: '.shop-search-result'
				offset: 8000

		ui:
			searchInput: 'input.search'
			results: '.shop-goods-search-result'
			childViewContainer: '.shop-search-result'
			childViewContainerWrapper: '.child-view-container-wrapper'
			clearSearch: '.clear-search'
			productDetailsRegion:'.shop-product-details-region'

		events:
			'click @ui.clearSearch': 'onClearSearchClick'

		childViewOptions: =>
			renderedIn: 'search'
			catalogOptions: @options.catalogOptions
			searchOptions: @vm

		initialize: ->
			@vm = {}
			@collection = new Iconto.REST.ShopGoodCollection()

			@state = new Iconto.shared.models.BaseStateViewModel _.extend {}, @options.catalogOptions,
				query: ''
				isLoading: false

			@infiniteScrollState.set
				limit: 20

			@listenTo @state,
				'change:query': _.debounce @onQueryStringChange,500

			@listenTo @collection,
				'add': @onCollectionAdd

			@cartCollection = @options.cartCollection

			@listenTo @cartCollection,
				'add': @onCartCollectionAdd
				'remove': @onCartCollectionRemove
				'reset': @onCartCollectionReset

		# VIEW EVENT HANDLERS
		onRender: =>
			@checkQueryValue @state.get('query')

		onShow: =>
			parsedQuery = Iconto.shared.helpers.navigation.getQueryParams()
			if @options.catalogOptions.product_id and parsedQuery.query
				@showProduct.doNotCloseOnFirstQueryStringUpdate = true
				@showProduct new Iconto.REST.ShopGood
					id: @options.catalogOptions.product_id

		onQueryStringChange: (model, value, options) =>
			@vm.savedUrlFragment = location.pathname+decodeURIComponent(location.search)

			if @showProduct.doNotCloseOnFirstQueryStringUpdate
				delete @showProduct.doNotCloseOnFirstQueryStringUpdate
			else
				@hideProduct()

			@trigger 'change:query', model,value,options

			if @checkQueryValue value
				_.defer => @reload()
			else
				@reset()

		onClearSearchClick: =>
			@state.set 'query', ''

		# CHILD VIEW EVENT HANDLERS
		onChildviewRender: (view) =>
			product = view.model
			return unless product
			if @findProductInCart product
				product.set 'inCart', true

		onChildviewProductClick: (view, model) =>
			@showProduct model

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
			currentCollectionProduct.set 'inCart', true

		onCartCollectionRemove: (product) =>
			currentCollectionProduct = @collection.get product.get('id')
			return unless currentCollectionProduct
			currentCollectionProduct.set 'inCart', false

		onCartCollectionReset: (type, product, cartCollection, options) =>
			@collection.each (m) ->
				if m.get('inCart') then m.set 'inCart', false

		# VIEW METHODS
		getQuery: =>
			query =
				query: @state.get('query')
				company_id: @state.get('company_id')

		reload: =>
			# TODO move cancel promise to _loadmore
			@state.set 'isLoading',true
			@reset()
			if @preloadPromise and not @preloadPromise.isFulfilled()
				@preloadPromise
				.done =>
					delete @preloadPromise
					@state.set 'isLoading',true
					@preloadPromise = @preload().cancellable()
					@preloadPromise
					.dispatch(@)
					.catch (error) ->
						console.error error
					.done =>
						@state.set 'isLoading', false
			else
				@state.set 'isLoading',true
				@preloadPromise = @preload().cancellable()
				@preloadPromise
				.dispatch(@)
				.catch (error) ->
					console.error error
				.done =>
					@state.set 'isLoading', false

		showProduct: (productModel) =>
			productModel.set
				headHref: _.get @, 'vm.savedUrlFragment'

			productViewOptions =
				model: productModel

			@productView = productView = new Views.ShopSearchDetailsView _.extend {},
				@childViewOptions(),
				productViewOptions
			productView.render()
			@ui.productDetailsRegion.empty().append productView.$el
			_.defer =>
				Marionette.triggerMethodOn(productView, 'show', productView, @, productViewOptions)

			@ui.productDetailsRegion.addClass 'is-visible'
			destroyView = productView.destroy
			productView.destroy = =>
				@ui.productDetailsRegion.removeClass 'is-visible'
				setTimeout =>
					destroyView.call productView
				,310

		hideProduct: =>
			if _.invoke [@],'ui.productDetailsRegion.hasClass', 'is-visible'
				@ui.productDetailsRegion.removeClass 'is-visible'
				setTimeout =>
					if @productView
						@productView.destroy()
				,310

		checkQueryValue: (value) =>
			if value.length < 1
				@trigger 'search:result:hide'
				return false
			else if value.length
				@trigger 'search:result:show'
				return true

		findProductInCart: (product) =>
			productId = _.invoke [product], 'get', 'id'
			return @cartCollection.get productId