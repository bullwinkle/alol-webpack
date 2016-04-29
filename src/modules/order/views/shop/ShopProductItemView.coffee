@Iconto.module 'order.views', (Views) ->

	class Views.ShopProductItemView extends Marionette.ItemView
		template: JST['order/templates/shop/shop-product-item']
		tagName: 'li'
		className: 'shop-product-item s-noselect s-cp'
		behaviors: Epoxy: {}

		ui:
			addToCart: '.add-to-cart'
			addToComparison: '.add-to-comparison'
			productPreview: '.image'
			amountSelector: '.count-selector'
			amountInput: '.count-selector [type=number]'
			amountSelectorInc: '.count-selector .increment'
			amountSelectorDec: '.count-selector .decrement'
			inputs: 'input, button, .rating'
			ratingStar: '.rating span'
			actions: '.actions'

		events:
			'click': 'onElClick'
			'click @ui.addToCart': 'onAddToCartButtonClicked'
			'click @ui.addToComparison': 'onAddToComparison'
			'click @ui.productPreview': 'onProductPreviewClick'
			'click @ui.amountSelectorInc': 'countIncrement'
			'click @ui.amountSelectorDec': 'countDecrement'
			'click @ui.inputs, @ui.actions': (e) -> e.stopPropagation()
#			'click @ui.ratingStar': 'onRatingClick'

		modelEvents:
			'change:count': 'onCountChange'

		bindings:
			"[data-add-to-cart]":		"text: select(inCart, 'Еще в корзину', 'В корзину')"
			"[data-add-to-comparison]":	"text: select(inComparison, 'В сравнении', 'К сравнению')"
			"[data-count-selector]":	"classes: {hide:not(count)}"
			"[data-count]":				"value: number(count), events: ['paste','change']"

		initialize: ->
			### awailable options are:
				root: Bool - rendered in root category collection;
				renderedIn: String - type of parent CollectionView ( 'category', 'search', 'cart' );
				renderedInCart: Bool - rendered in Cart-collection or not;
				renderedInSearchResult: Bool - rendered in SearchResult-collection or not;
				catalogOptions: Object - global catalog options, passed from root catalog Layout (company_id, user etc.);
			###
			@model.set 'href', @getLinkToBack()
			if @options.renderedIn is 'search' and @model.get('image_url') isnt @model.defaults.image_url
				@model.set 'image', @model.get('image_url')


			### TODO optimize this shit:
				- move this control with Cart-service to parent collection
			###
#			switch @options.renderedIn
#				when 'category', 'search'
#					@cartCollection = new Iconto.shared.services.Cart {companyId}
#
#					productInCart = @productInCart @cartCollection
#					if productInCart
#						count = productInCart.get 'count'
#						@cartCollection.remove productInCart
#						@cartCollection.set @model, remove:false
#						@model.set
#							count: count
#							inCart: true

		getLinkToBack: =>
			companyId = _.get(@,'options.catalogOptions.company_id',0)
			addressId = _.get(@,'options.catalogOptions.address_id',0)
			categoryId = _.get(@,'options.parentCategoryId',0)
			productId = _.invoke([@],'model.get','id')[0] || 0
			queryParams = _.get(@,'options.catalogOptions.queryParams','')

			href = ""
			href += "/wallet/company/#{	companyId }" if companyId
			href += "/address/#{ addressId }" if addressId
			href += "/shop/category/#{ categoryId }" if categoryId
			href += "#{if !categoryId then '/shop' else ''}/product/#{ productId }" if productId
			href += queryParams if queryParams
			href

		onElClick: (e) =>
			e.stopPropagation()
			return false if @options.renderedIn is 'cart'
			Iconto.shared.router.navigate @model.get 'href'
			@trigger 'product:click', @model

		handle: (e, handler) =>
			e.preventDefault()
			e.stopPropagation()
			handler(e) if _.isFunction handler
			return false

		onProductPreviewClick: (e) => @handle e, =>
			src = @model.get('image')

			Iconto.shared.views.modals.LightBox.show
				img: src

		onCountChange: (model, count, options) =>
#			console.log 'product count change'
#			return false if @options.renderedIn is 'cart'
#			if count
#				@cartCollection.set @model, remove: false
#			else
#				@cartCollection.remove @model

		onAddToCartButtonClicked: (e) => @handle e, =>
			@trigger 'product:addToCart', @model
#			currentCount = @model.get('count') or 0
#			@model.set
#				count: currentCount+1
#				inCart: true
#
#			unless currentCount
#				_.defer =>
#					alertify.success "Товар добавлен в корзину"

		onAddToComparison: (e) => @handle e, =>
			# TODO implement some logic about comparision
			@trigger 'product:addToComparison'
			@model.set 'inComparison', !@model.get('inComparison')
#
#		countIncrement: (e) => @handle e, =>
#			if @ui.amountInput.val() > 0
#				@model.set 'count', @model.get('count')+1
#			else
#				@model.set 'count', 0
#
#		countDecrement: (e) => @handle e, =>
#			if @ui.amountInput.val() > 0
#				@model.set 'count', @model.get('count')-1
#			else
#				@model.set 'count', 0
#
#		onRatingClick: (e) => # not used now
#			e.stopPropagation()
#			$this = $(e.currentTarget)
#			$this
#			.addClass 'is-active'
#			.siblings()
#			.removeClass 'is-active'
#
#		productInCart: (cartCollection) =>
#			return cartCollection.get @model.get('id')