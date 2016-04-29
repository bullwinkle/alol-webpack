#= require ./ShopProductReviewsView

@Iconto.module 'order.views', (Views) ->
	['is-loading', 'is-checked', 'is-opened']

	class Views.ShopProductDetailsView extends Marionette.LayoutView
		template: JST['order/templates/shop/shop-product-details']
		className: 'shop-product-details is-loading'
		childViewContainer: '.list-container'

		behaviors:
			Epoxy: {}

		regions:
			reviewsRegion: '[reviews-region]'

		ui:
			head: '.head:eq(0)'
			addToCart: '.add-to-cart'
			addToComparison: '.add-to-comparison'
			productImages: '.product-icon'
			productImage: '.product-icon .image img'
			amountSelector: '.count-selector'
			amountInput: '.count-selector [type=number]'
			amountSelectorInc: '.count-selector .increment'
			amountSelectorDec: '.count-selector .decrement'
			inputs: 'input, button, .rating'
			infoTabs: '.tabs'
			rating: '.rating'
			ratingWrapper: '.rating-wrapper'
			ratingSmallWrapper: '.rating-wrapper-small'
			scrollWrapper: '.product-wrapper'

		events:
			'click @ui.head': 'onHeadClick'
			'click @ui.addToCart': 'onAddToCartButtonClick'
			'click @ui.addToComparison': 'onAddToComparison'
			'click @ui.productImage': 'onProductPreviewClick'
			'click @ui.amountSelectorInc': 'countIncrement'
			'click @ui.amountSelectorDec': 'countDecrement'
			'click @ui.inputs': 'stopPropagation'

		initialize: ->
			@model = if @options.model instanceof Backbone.Model
				@options.model
			else
				new Iconto.order.ShopGoodModel @options.model

			@updateHeadLink()

			companyId = _.get(@, 'options.catalogOptions.company_id', 0)
			@cartCollection = new Iconto.shared.services.Cart {companyId}
			@listenTo @cartCollection,
				'add': @onCartCollectionAdd
				'remove': @onCartCollectionRemove
				'reset': @onCartCollectionReset

		# VIEW EVENT HANDLERS
		onRender: =>
			window.d = @
			@ui.infoTabs.contentTabs()

			@modelFetchPromise = @model.fetch(null, {reload: true})
			.then =>
				@updateHeadLink()

				unless @model.get('count')
					@model.set 'count', 1

				productInCart = @findProductInCart @model

				if productInCart
					@model.set
#						count: productInCart.get('count') || 1
						count: 1
						inCart: true

				comRating = new Iconto.shared.components.Rating
					value: @model.get('rating')
					readOnly: true
				.render()

				comRatingSmall = new Iconto.shared.components.Rating
					value: @model.get('rating')
					readOnly: true
					mod: 'm-lighter l-p-a l-b-0 l-r-10 f-sz-18'
				.render()

				@listenTo @model, 'change:rating', (model, rating) =>
					comRating.set rating
					comRatingSmall.set rating

				@ui.ratingWrapper.append comRating.$el
				@ui.ratingSmallWrapper.append comRatingSmall.$el

				_.defer =>
					@ui.productImages.slick
						infinite: true
						dots: true
						speed: 220
						slidesToShow: 1
						slidesToScroll: 1
						lazyLoad: 'ondemand'
						arrows: true
						responsive: [
							{
								breakpoint: 821
								settings: {
									arrows: false
								}
							}
						]

					@$el.removeClass 'is-loading'

		onShow: =>
			@modelFetchPromise
			.then =>
				reviewsView = new Views.ShopProductReviewsView
					scrollable: @ui.scrollWrapper
					persistentId: @model.get('persistent_id')

				@listenTo reviewsView,
					'reviews:updated': =>
						defer = =>
							@model.fetch(null, {reload: true})
						setTimeout defer, 1000

				@reviewsRegion.show reviewsView

		onHeadClick: (e) =>
			@destroy()

		onProductPreviewClick: (e) =>
			e.stopPropagation()
			src = $(e.currentTarget).data('src')
			return false unless src
			Iconto.shared.views.modals.LightBox.show
				img: src

		onAddToCartButtonClick: (e) =>
			e.stopPropagation()
			return unless @model.get('count')
			productInCart = @findProductInCart @model
			if productInCart
				productInCart.set
					count: +productInCart.get('count') + (@model.get('count') || 1)
			else
				@cartCollection.set @model.toJSON(), remove: false

			@model.set('count', 1)

			_.defer =>
				_.invoke [@cartCollection], 'logger.logProductAdd', productInCart or @model

		onAddToComparison: (e) =>
			# TODO implement some logic about comparision
			@model.set 'inComparison', !@model.get('inComparison')


		# CART-COLLECTION EVENT HANDLERS (do not interact with CART here, just with current view)
		onCartCollectionAdd: (product) =>
			currentProduct = @model.get('id') is product.get('id')
			return unless currentProduct
			@model.set
				inCart: true
				count: product.get('count') || 1

		onCartCollectionRemove: (product) =>
			currentProduct = @model.get('id') is product.get('id')
			return unless currentProduct
			@model.set
				inCart: false
				count: 1 # count here need to be 1 or more, because it define how mach will be added to cart

		onCartCollectionReset: (type, product, cartCollection, options) =>
			@model.set
				inCart: false
				count: 1 # count here need to be 1 or more, because it define how mach will be added to cart

		# VIEW METHODS
		countIncrement: (e) =>
			e.stopPropagation()
			@model.set 'count', @model.get('count') + 1

		countDecrement: (e) =>
			e.stopPropagation()
			if @model.get('count') <= 1
				return @model.set 'count', 1
			@model.set 'count', @model.get('count') - 1

		getLinkToBack: =>
			companyId = _.get(@, 'options.catalogOptions.company_id', 0)
			addressId = _.get(@, 'options.catalogOptions.address_id', 0)
			parentCategoryId = _.get(@, 'options.catalogOptions.category_id', 0)
			productId = _.get(@, 'options.catalogOptions.product_id', 0)
			queryParams = _.get(@, 'options.catalogOptions.queryParams', '')

			headHref = ""
			headHref += "/wallet/company/#{ companyId }" if companyId
			headHref += "/address/#{ addressId }" if addressId
			headHref += "/shop"
			headHref += "#{ if parentCategoryId then "/category/#{parentCategoryId}" else '' }"
			# headHref += "/product/#{ productId }" if productId
			#			headHref += queryParams if queryParams

			headHref

		stopPropagation: (e) =>
			e.stopPropagation()

		updateHeadLink: =>
			@model.set
				headHref: @getLinkToBack()
				headTitle: @model.get('title')

		findProductInCart: (product) =>
			productId = _.invoke [product], 'get', 'id'
			return @cartCollection.get productId