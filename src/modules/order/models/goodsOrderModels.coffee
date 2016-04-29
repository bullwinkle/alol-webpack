Iconto.module 'order.models', (Models) ->
	#MODELS
	class Models.ShopGoodModel extends Iconto.REST.RESTModel
		urlRoot: 'shop-good'
		defaults:
			id : 0
			amount: 0
			shop_category_id : 0
			company_id : 0
			image_id : 0
			image_url : ''
			title : ''
			description : ''
			is_active : true
			external_id : 0
			price : 0
			created_at: 0
			updated_at: 0
			deleted: false
			deleted_at: 0

	class Models.ShopGoodCollection extends Iconto.REST.RESTCollection
		url: 'shop-good'
		model: Models.ShopGoodModel


	class Models.ShopCategoryModel extends Iconto.REST.RESTModel
		urlRoot: 'shop-catalogue'
		defaults:
			id: 0
			title: ''
			description: ''
			parent_id: 0
			company_id: 0
			image_id: 0
			external_id: 0
			created_at: 0
			updated_at: 0
			deleted: false
			deleted_at: 0


	class Models.ShopCategoriesCollection extends Iconto.REST.RESTCollection
		url: 'shop-catalogue'
		model: Models.ShopCategoryModel


	class Models.ShopOrderModel extends Iconto.REST.RESTModel
		urlRoot: ''
		defaults:
			id: 0
			user_id: 0
			company_id: 0
			shop_goods: []
			description: ''
			amount: 0
			delivery_amount: 0
			total_amount: 0
			delivery_at: 0
			created_at: 0
			updated_at: 0
			deleted: false
			deleted_at: 0

	class Models.ShopOrdersCollection extends Iconto.REST.RESTCollection
		url: ''
		model: Models.ShopOrderModel