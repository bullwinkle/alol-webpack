#= require_tree ./

@Iconto.module 'order.views', (Views) ->

	class Views.ShopLayout extends Marionette.LayoutView

		rightButtonBlocked = false
		leftButtonBlocked = false

		showedIn: 'front' # available params: 'back-office'

		className: 'shop-layout mobile-layout'

		template: JST['order/templates/shop/shop-layout']

		regions:
			catalogRegion: '#catalog-region .shop-catalog-region'

			searchRegion: '#search-region .shop-catalog-region'

			checkoutRegion: '#checkout-region .shop-catalog-region'

			reviewRegion: '#review-region .shop-catalog-region'

		ui:
			topbar: '.topbar-region'
			topbarLeftButton: '.topbar-region .left-small'
			topbarRightButton: '.topbar-region .right-small'
			viewContent: '.view-content'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'

		behaviors: =>
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		initialize: (options) ->
			@vm = {}
			stateNames = [
				'catalog'
				'search'
				'checkout'
			]

			@state = new Iconto.shared.models.BaseStateViewModel _.extend {},
				stateName: 'catalog'
				topbarTitle: 'Каталог'

#				topbarLeftButtonClass: 'visible hide-on-web-view'
#				topbarLeftButtonDisabled: false
#				topbarLeftButtonSpanClass: 'ic-chevron-left'
#				topbarLeftButtonSpanText: ''

				topbarRightButtonClass: 'text-button visible'
				topbarRightButtonDisabled: false
				topbarRightButtonSpanClass: 'ic-cart-2 goods-count'
				topbarRightButtonSpanText: '0' # ordered goods counter here
				reviewVisible: false

			handle = _.debounce =>
				@vm.savedUrlFragment = location.pathname+decodeURIComponent(location.search)
			,10

			@listenTo @state,
				'change:page': handle
				'change:subpage': handle
				'change:company_id': handle
				'change:address_id': handle
				'change:category_id': handle
				'change:queryParams': handle
				'change:stateName': @onStateChange

			@state.set @options # need to be here to trigger 'state:change...' and show proper state on first render

			@cartCollection = new Iconto.shared.services.Cart
				companyId: options.company_id

			@listenTo @cartCollection, 'add remove update reset change', _.debounce @onCartCollectionChange, 100

			@listenTo Iconto.events,
				'catalog:reviewForm:show': @showReviewForm
				'catalog:reviewForm:hide': @hideReviewForm

		onRender: =>
			@cartCollection.trigger 'change'
			@ui.viewContent.removeAttr 'data-scroll'

			@loadDeps()
			.then @renderCheckout
			.then @renderCatalog
			.then @renderSearch
			.then =>
				@state.set 'isLoading',false

				if @state.get('subpage') is 'cart'
					@showCheckout "/wallet/company/#{@options.company_id}/shop/"

		loadDeps: =>
			promises = []
			companyId = @state.get('company_id')
			addressId = @state.get('address_id')
			if companyId then promises.push (new Iconto.REST.Company(id: companyId)).fetch()
			if addressId then promises.push (new Iconto.REST.Address(id: addressId)).fetch()
			Q.settle promises
			.then ([company, address]) =>
				topbarSubtitle = ''
				company =  _.result company, 'value', {}
				address =  _.result address, 'value', {}

				if @showedIn == 'front'
					if company.name
						topbarSubtitle += "#{company.name}"
					if address.address
						topbarSubtitle += " (#{address.address})"

				@state.set {topbarSubtitle, company, address}

			.catch (err) =>
				console.warn err

		onStateChange: (state, stateName, options) =>
			switch stateName
#				when 'catalog'
#				when 'search'
				when 'checkout'
					@state.set
						topbarLeftButtonClass: 'visible hide-on-web-view'
						topbarLeftButtonDisabled: false
						topbarLeftButtonSpanClass: 'ic-chevron-left'
						topbarLeftButtonSpanText: ''

						topbarRightButtonClass:"text-button visible"
						topbarRightButtonDisabled: false
						topbarRightButtonSpanClass: " " #space need to be here, this is a crutch
						topbarRightButtonSpanText: "Очистить"

				else
					if @state.get('reviewVisible')
						@state.set
							topbarLeftButtonClass: 'visible hide-on-web-view'
							topbarLeftButtonDisabled: false
							topbarLeftButtonSpanClass: 'ic-chevron-left'
							topbarLeftButtonSpanText: ''

							topbarRightButtonClass:"text-button visible"
							topbarRightButtonDisabled:false
							topbarRightButtonSpanClass:"ic-cart-2 goods-count"
							topbarRightButtonSpanText:"#{@cartCollection.length}"
					else
						@state.set
							topbarLeftButtonClass: @state.defaults.topbarLeftButtonClass
							topbarLeftButtonDisabled: @state.defaults.topbarLeftButtonDisabled
							topbarLeftButtonSpanClass: @state.defaults.topbarLeftButtonSpanClass
							topbarLeftButtonSpanText: @state.defaults.topbarLeftButtonSpanText

							topbarRightButtonClass:"text-button visible"
							topbarRightButtonDisabled:false
							topbarRightButtonSpanClass:"ic-cart-2 goods-count"
							topbarRightButtonSpanText:"#{@cartCollection.length}"

		renderCatalog: =>
			Q.fcall =>
				view = new Views.ShopCatalogLayout
					parentView: @
					cartCollection: @cartCollection
					catalogOptions: @options
				@catalogRegion.show view

		renderSearch: =>
			Q.fcall =>
				view = new Views.ShopSearchView
					parentView: @
					cartCollection: @cartCollection
					catalogOptions: @options

				@listenTo view,
					'search:result:hide': =>
						if _.get @, 'vm.savedUrlFragment'
							Iconto.shared.router.navigate @vm.savedUrlFragment,
								trigger:false
								replace:true
						@state.set 'stateName', 'catalog'
					'search:result:show': =>
						@state.set 'stateName', 'search'

				@searchRegion.show view if @searchRegion

		renderCheckout: =>
			Q.fcall =>

				view = new Views.ShopCartView
					parentView: @
					catalogOptions: @options
					collection: @cartCollection

				@listenTo view,
					'order:success': (data) =>
						@trigger 'order:success', data
					'storage:reset': =>
						@trigger 'storage:reset'

				@checkoutRegion.show view if @checkoutRegion

		onTopbarLeftButtonClick: (e) =>
			switch @state.get 'stateName'
				when 'checkout'
					e.stopPropagation()
					@hideCheckout()
					return false
				else
					if @state.get 'reviewVisible'
						e.stopPropagation()
						@hideReviewForm()
						return false

		onTopbarRightButtonClick: (e) =>
			e.stopPropagation()
			switch @state.get 'stateName'
				when 'checkout'
					return false unless @cartCollection.length
					Iconto.shared.views.modals.Confirm.show
						message: 'Удалить все товары из корзины?'
						onSubmit: => @cartCollection.reset()
				else
					@showCheckout()

		showReviewForm: ({rating,product,currentReview}={rating:0,product:{},currentReview:{}}) =>
			reviewView = new Views.ShopProductReviewEditView {rating,product,model:currentReview}
			@reviewRegion.show reviewView
			@state.set
				reviewVisible: true
				topbarLeftButtonClass: 'visible hide-on-web-view'
				topbarLeftButtonDisabled: false
				topbarLeftButtonSpanClass: 'ic-chevron-left'
				topbarLeftButtonSpanText: ''

		hideReviewForm: =>
			@state.set
				reviewVisible:false
				topbarLeftButtonClass: @state.defaults.topbarLeftButtonClass
				topbarLeftButtonDisabled: @state.defaults.topbarLeftButtonDisabled
				topbarLeftButtonSpanClass: @state.defaults.topbarLeftButtonSpanClass
				topbarLeftButtonSpanText: @state.defaults.topbarLeftButtonSpanText

			setTimeout =>
				@reviewRegion.empty()
			, 310

		hideCheckout: =>
			prevState = @state.previous 'stateName'
			if prevState is 'checkout' then prevState = 'catalog'

			backRoute = @state.get 'backRoute'
			defaultRoute = if backRoute
				backRoute
			else
				"/wallet/company/#{@options.company_id}/shop/"

			@state.set 'stateName': prevState
			Iconto.shared.router.navigate defaultRoute, trigger: false

		showCheckout: (backRoute=location.pathname+location.search+location.hash) =>
			@state.set
				'backRoute': backRoute
				'stateName': 'checkout'
			route = "/wallet/company/#{@options.company_id}/shop/cart"
			Iconto.shared.router.navigate route

		goBack: =>
			defaultRoute = "/wallet/cards"
			parsedUrl = Iconto.shared.helpers.navigation.parseUri()
			fromRoute = _.get parsedUrl, 'query.from'
			route = fromRoute or defaultRoute
			Iconto.shared.router.navigate route, trigger: true

		onCartCollectionChange: (productModel, cartCollection, options) =>
			return false if @state.get('stateName') is 'checkout'
			@state.set
				topbarRightButtonSpanText: "#{@cartCollection.length}"
#				topbarRightButtonDisabled: @cartCollection.length < 1