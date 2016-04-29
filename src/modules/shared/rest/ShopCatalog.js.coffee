# TODO global rename ShopGood -> ShopProduct
# TODO global rename ShopGoodCollection -> ShopProductCollection
class Iconto.REST.ShopGood extends Iconto.REST.RESTModel
	@TYPE = 2

	defaultImgUrl = ICONTO_WEBSOCKET_URL + 'static/images/original/default.jpg'

	constructor: ->
		super
		_.extend @, Backbone.Validation.mixin

	urlRoot: 'shop-good'

	defaults:
		# short attributes list
		type: ""
		title: ""
		image: defaultImgUrl # product thumbnail
		price: 0
		discount_price: 0
		count: 0

		# full attributes list
		shop_category_id: 0
		company_id: 0
		images: [defaultImgUrl] # product gallery
		image_id: 0 # product thumbnail id, uses in office module
		image_url: defaultImgUrl # product thumbnail, uses in office module
		description: ''
		is_active: true
		external_id: null
		deleted: ""
		pack_type: ""
		parent_id: ""
		updated_at: ""
		rating: 0
		rating_count: 0
		params: []

		#uses just for bindings
		headTitle: ""
		headHref:""
		inComparison: false
		inCart: false
		totalSum: 0

	parse: (response, options) =>
		# remove all empty strings, because empty strings (e.g. image_url) overvrites model defaults and this is bad
		_.omit response, (val, key, obj) =>
			return _.isString(val) and !val

	serialize: (data) =>
		# remove fields, used just for bindings
		_.omit data, [
			'headTitle'
			'href'
			'inComparison'
			'inCart'
			'totalSum'
		]

	validation:
		title:
			required: true
			minLength: 3
			maxLength: 200
		shop_category_id:
			required: true
			min: 1
			msg: 'Выберите категорию'
		company_id:
			required: true
		image_id:
			required: true
			min: 0
		description:
			maxLength: 2048
		price:
			required: true
			pattern: 'number'
			max: 100000
		count:
			max: 1000

class Iconto.REST.ShopGoodCollection extends Iconto.REST.RESTCollection # used just in search view
	url:'shop-good'
	model: Iconto.REST.ShopGood



class Iconto.REST.ShopCategory extends Iconto.REST.RESTModel
	@TYPE = 1

	constructor: ->
		super
		_.extend @, Backbone.Validation.mixin

	urlRoot: 'shop-category'

	defaults:
		title: ''
		company_id: 0
		image_id: 0
		parent_id: 0
		external_id: 0

		#uses just for bindings
		headTitle: ""
		headHref:""

	serialize: (data) =>
		_.omit(data, [
			'headTitle'
			'href'
		])

	validation:
		title:
			required: true
		company_id:
			required: true

class Iconto.REST.ShopCategoryCollection extends Iconto.REST.RESTCollection
	url: 'shop-category'
	model: Iconto.REST.ShopCategory


class Iconto.REST.ShopCatalogCollection extends Iconto.REST.RESTCollection
	url: 'shop-catalogue'
	model: (attrs, options) ->
		ModelClass = switch attrs.type
			when Iconto.REST.ShopGood.TYPE then Iconto.REST.ShopGood
			when Iconto.REST.ShopCategory.TYPE then Iconto.REST.ShopCategory

		new ModelClass attrs, options
