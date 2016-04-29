@Iconto.module 'order.views', (Views) ->

	class Views.ShopCatalogLayout extends Marionette.LayoutView
		template: JST['order/templates/shop/shop-catalog']
		className: 'shop-catalog-layout'

		regions:
			categoriesRegion: '.shop-category-tree-view-region'
			productDetailsRegion:
				el:'.shop-product-details-region'
				regionClass: Iconto.shared.regions.AnimatableRegion
				visibleClass: 'is-visible'

		ui:
			openedCategoriesContainer: '.shop-opened-categories-container'

		initialize: ->

			@vm = {
				categoriesRegionsCounter: 0
			}
			@state = if @options.state instanceof Backbone.Model
				@options.catalogOptions
			else
				new Iconto.shared.models.BaseStateViewModel @options.catalogOptions

			@state.set 'categoriesRegions', 0

			@categoryHistory = []

		onRender: =>
			@showCategories()

		onShow: =>

			### available options are:

			page : "shop"
			subpage : null or "product" or "category"
			company_id : null or Number
			address_id : null or Number
			category_id : null or Number
			product_id : null or Number
			queryParams : false or Object (parsed query params)
			user : Object

			###
			# TODO move this logic to 'update' method and trigger it when catalogOptions changed
			parsedQuery = Iconto.shared.helpers.navigation.getQueryParams()

			if @options.catalogOptions.product_id and !parsedQuery.query
				@showProduct new Iconto.REST.ShopGood
					id: @options.catalogOptions.product_id

			if @options.catalogOptions.category_id
				@showCategory new Iconto.REST.ShopCategory
					id: @options.catalogOptions.category_id

		showCategories: =>

			Q.fcall =>
				view = new Views.ShopCategoryView
					model: null
					catalogOptions: @options.catalogOptions
					root:true

				@listenTo view,
					'category:click': @showCategory
					'product:click': @showProduct

				@categoriesRegion.show view if @categoriesRegion

		showCategory: (categoryModel) =>
			@categoryHistory.push categoryModel.get 'id'
			@options.catalogOptions.prevCategoryId = @categoryHistory[@categoryHistory.length-2]

			view = new Views.ShopCategoryView
				model: categoryModel
				catalogOptions: @options.catalogOptions
				root: false

			@listenTo view,
				'category:click': @showCategory
				'product:click': @showProduct

			@addCategoryRegion()
			.then (region) =>
				region.show view

		showProduct: (productModel) =>
			productView = new Views.ShopProductDetailsView
				model: productModel
				catalogOptions: @options.catalogOptions
			@productDetailsRegion.show productView

		addCategoryRegion: =>
			new Promise (resolve, reject) =>
				@vm.categoriesRegionsCounter++
				newRegionId = "category-region-#{@vm.categoriesRegionsCounter}"
				newRegionClassName = "shop-category-products-region level-#{@vm.categoriesRegionsCounter}"
				newRegionInlineCss = "z-index:#{100 + @vm.categoriesRegionsCounter*10}"
				newRegionName = _.camelCase newRegionId
				$newRegionEl = $("<div id=\"#{newRegionId}\" class=\"#{newRegionClassName}\" style=\"#{newRegionInlineCss}\" data-prevent-scroll></div>")
				$newRegionEl.appendTo @ui.openedCategoriesContainer
				newRegion = @addRegion newRegionName,
					el:$newRegionEl
					regionClass: Iconto.shared.regions.AnimatableRegion
					visibleClass: 'is-visible'
					name: newRegionName
					index: @vm.categoriesRegionsCounter

				@listenToOnce newRegion,
					'empty', => @removeCategoryRegion(newRegion)

				resolve(newRegion)

		removeCategoryRegion: (region) =>
			new Promise (resolve, reject) =>
				index = region.options.index
				regionName = region.options.name
				$regionEl = region.$el

				@removeRegion regionName
				$regionEl.remove()
				@vm.categoriesRegionsCounter--
				resolve(@vm.categoriesRegionsCounter)

		removeAllCategoryRegions: (p) =>
			p ||= Promise.defer()

			@removeCategoryRegion()
			.then () =>
				if !@vm.categoriesRegionsCounter
					p.resolve(@vm.categoriesRegionsCounter)
				else
					setTimeout @removeAllCategoryRegions.bind(@,p)
			.catch (err) =>
				console.warn 'err',err
				p.reject err
			.done()

			p.promise