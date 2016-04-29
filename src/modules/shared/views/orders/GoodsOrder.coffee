Iconto.module 'shared.views.orders', (Orders) ->

	class GoodsCategoryViewModel extends Backbone.Model

	#VIEWS
	class Orders.GoodView extends Marionette.ItemView
		template: JST['shared/templates/orders/shop-good']
		tagName: 'li'
		className: 'goods-view'
		initialize: ->
			console.log 'GoodsView', @options

		onRender: =>

	class Orders.GoodsCategoryView extends Marionette.CompositeView
		template: JST['shared/templates/orders/shop-category']
		tagName: 'li'
		className: 'goods-category-view list-item s-unstyled l-pr-0 l-p-r'
		childViewContainer: '.list-container'

		ui:
			title: 'h1'
			childContainer: '.list-container'
			childContainerToggler: '.child-container-toggler'

		events:
			'click': 'onClick'

		initialize: ->
			@state = new Backbone.Model()
			@collection = new Iconto.shared.models.orders.ShopCategoriesCollection @model.get('subCategories')
			@goodsCollection = new Iconto.REST.ShopGoodCollection()

			unless @model.get('subCategories')
				@state.set 'mostInner', true

		onRender: =>

		onClick: (e) =>
			console.log 'click',e
			e.stopPropagation()
			@ui.childContainer.toggleClass 'hide'
			if @state.get('mostInner')
				@goodsCollection.fetch('shop_category_id': @model.get('id'))
				.then (res) =>
					@childView = Orders.GoodView
					@collection.add res
				.catch (err) =>
					console.error err
				.done()

	class Orders.GoodsCategoriesView extends Marionette.CollectionView
		template: JST['shared/templates/orders/shop-categories']
		tagName: 'ul s-unstyled'
		className: 'goods-categories-view list'
		childView: Orders.GoodsCategoryView
		initialize: ->
			@model = new GoodsCategoryViewModel()
			@collection = new Iconto.shared.models.orders.ShopCategoriesCollection()

		onRender: =>
			(new Iconto.shared.models.orders.ShopCategoriesCollection()).fetch()
			.then (categories) =>
				categories = @prepareData categories
				@collection.add categories
			.catch (err) =>
				console.error err
			.done()

		prepareData: (array) => # TODO standartize this
			rootCategories = []
			subCategories = []
			for category in array
				if category.parent_id
					subCategories.push category
				else
					rootCategories.push category

			for subCategory in subCategories
				do (subCategory) =>
					rootCategory = _.find rootCategories, (category) -> category.id is subCategory.parent_id
					rootCategory.subCategories = rootCategory.subCategories or []
					rootCategory.subCategories.push subCategory

			rootCategories
