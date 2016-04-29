@Iconto.module 'order.views', (Views) ->

	class Views.ShopCartItemView extends Marionette.ItemView
		template: JST['order/templates/shop/shop-cart-item']
		tagName: 'li'
		className: 'shop-product-item l-table-row'
		behaviors: Epoxy: {}

		ui:
			productPreview: '.image'
			amountSelector: '.count-selector'
			amountInput: '[name=count]'
			amountSelectorInc: '.count-selector .increment'
			amountSelectorDec: '.count-selector .decrement'
			inputs: 'input, button, .rating'
			actions: '.actions'
			removeFromCart: '.remove-from-cart'

		events:
			'click @ui.removeFromCart': 'onRemoveFromCartClick'
			'click @ui.productPreview': 'onProductPreviewClick'
			'click @ui.amountSelectorInc': 'countIncrement'
			'click @ui.amountSelectorDec': 'countDecrement'
			'click @ui.inputs, @ui.actions': (e) -> e.stopPropagation()

		modelEvents:
			'change:count': 'onCountChange'

		bindings:
			"[data-add-to-cart]":		"text: select(inCart, 'В корзинe', 'В корзину')"
			"[data-add-to-comparison]":	"text: select(inComparison, 'В сравнении', 'К сравнению')"
			"[data-count-selector]":	"classes: {hide:not(count)}"
			"[data-count]":				"value: number(count), events: ['paste','change']"
			"[data-count-2]":			"value: number(count), events: ['paste','change']"
			"[data-total-sum]":			"text: number(totalSum)"

		initialize: ->
			### awailable options are:
				root: Bool - rendered in root category collection;
				renderedIn: String - type of parent CollectionView ( 'category', 'search', 'cart' );
				renderedInCart: Bool - rendered in Cart-collection or not;
				renderedInSearchResult: Bool - rendered in SearchResult-collection or not;
				catalogOptions: Object - global catalog options, passed from root catalog Layout (company_id, user etc.);
			###
			@calculateTotal()

		handle: (e, handler) =>
			e.preventDefault()
			e.stopPropagation()
			handler(e) if _.isFunction handler
			return false

		onRemoveFromCartClick: =>
			_.invoke [@], 'options.cartCollection.remove', @model

		onProductPreviewClick: (e) => @handle e, =>
			src = @model.get('image')
			Iconto.shared.views.modals.LightBox.show
				img: src

		onCountChange: (model, count, options) =>
			if count < 2 then model.set('count',1)
			@calculateTotal()

		countIncrement: (e) => @handle e, =>
			@model.set 'count', @model.get('count')+1

		countDecrement: (e) => @handle e, =>
			return if @model.get('count') < 2
			@model.set 'count', @model.get('count')-1

		calculateTotal: =>
			currentPrice = if @model.get('discount_price') and @model.get('discount_price') < @model.get('price')
				+@model.get('discount_price')
			else
				+@model.get('price')
			@model.set
				totalSum: currentPrice * +@model.get('count')