@Iconto.module 'order.views', (Views) ->

	['is-loading', 'is-checked', 'is-opened']

	class Views.ShopCategoryItemView extends Marionette.ItemView
		tagName: 'li'
		className: 'shop-category-item is-hidden'
		template: JST['order/templates/shop/shop-category-item']
		childViewContainer: '.list-container'

		ui:
			head: '.head:eq(0)'

		events:
			'click @ui.head': 'onElClick'

		initialize: ->
			@model.set 'href', @getHref()

		onShow: =>
			@$el.removeClass 'is-hidden'

		handle: (e, handler) =>
			e.preventDefault()
			e.stopPropagation()
			handler(e) if handler
			return false

		onElClick: (e) =>
			@trigger 'category:click', @model

		getHref: =>
			companyId = _.get(@,'options.catalogOptions.company_id',0)
			addressId = _.get(@,'options.catalogOptions.address_id',0)
			categoryId = _.invoke([@],'model.get','id')[0] || 0
			productId = _.get(@,'options.catalogOptions.product_id',0)
			queryParams = _.get(@,'options.catalogOptions.queryParams','')

			href = ""
			href += "/wallet/company/#{	companyId }" if companyId
			href += "/address/#{ addressId }" if addressId
			href += "/shop/category/#{ categoryId }" if categoryId
			# href += "/product/#{ productId }" if productId
#			href += queryParams if queryParams
			href