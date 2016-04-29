class Iconto.REST.Coupon extends Iconto.REST.RESTModel
	urlRoot: 'coupon'
	defaults:
		hash: ''
		title: ''
		description: ''
		url: ''
		images: []
		company_id: 0

	validation:
		title:
			required: true
			minLength: 3
			maxLength: 250
		description:
			required: true
			maxLength: 1000
		company_id:
			required: true
		images:
			minSize: 1

_.extend Iconto.REST.Coupon::, Backbone.Validation.mixin

class Iconto.REST.CouponCollection extends Iconto.REST.RESTCollection
	url: 'coupon'
	model: Iconto.REST.Coupon