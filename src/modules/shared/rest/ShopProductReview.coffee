#ГЕТ все комментарии к товару
#https://dev.alol.io/rest/2.0/shop-good-reviews?filters[persistent_id]=773196&conditions[user_id][<>]=800
#
#ГЕТ проверить пользователя
#https://dev.alol.io/rest/2.0/shop-good-review?filters[persistent_id]=441820&filters[user_id]=298105

class Iconto.REST.ShopProductReview extends Iconto.REST.RESTModel
	
	defaultImgUrl = ICONTO_WEBSOCKET_URL + 'static/images/original/default.jpg'
	
	constructor: ->
		super
		_.extend @, Backbone.Validation.mixin

	urlRoot: 'shop-good-review'

	defaults:
		id: 0,
		persistent_id: 0,
		user_id: 0,
		rating: 0,
		comment: "",
		updated_at: 0,
		created_at: 0,
		defaultImgUrl: defaultImgUrl
		user: {
			user_name: "Аноним",
			user_photo: defaultImgUrl
		}
#
#	parse: (response, options) => response
#
	serialize: (data) =>
		_.pick data, [
			'persistent_id',
			'user_id',
			'rating',
			'comment'
		]

	validation: {}

class Iconto.REST.ShopProductReviewCollection extends Iconto.REST.RESTCollection # used just in search view
	url:'shop-good-reviews'
	model: Iconto.REST.ShopProductReview
