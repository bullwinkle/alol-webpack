#= require order/views/shop/ShopProductItemView

@Iconto.module 'order.views', (Views) ->

	class Views.ShopSearchItemView extends Views.ShopProductItemView
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
			href

		onProductPreviewClick: (e) => @handle e, =>
			src = @model.get('image')

			Iconto.shared.views.modals.LightBox.show
				img: src