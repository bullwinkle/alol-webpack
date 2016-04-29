class Iconto.REST.ShopOrder extends Iconto.REST.RESTModel

	urlRoot: 'shop-order'

	@ORDER_STATUS_PENDING = ORDER_STATUS_PENDING = 0
	@ORDER_STATUS_CANCEL = ORDER_STATUS_CANCEL = 1
	@ORDER_STATUS_APPROVE = ORDER_STATUS_APPROVE = 2

	defaults:
		phone: ''
		company_id: 0
		shop_goods: [] # format: [{shop_good_id: 43, count: 1}, {shop_good_id: 57, count: 2}]

		status: ORDER_STATUS_PENDING
		user_id: 0
		address_id: 0
		address: ''
		amount: 0 #order summ
		total_amount: 0
		description: ''

		delivery_amount: 0
		delivery_at: 0
		delivery_date: ""
		delivery_time: 0 # index in workPeriods
		payment_method: 0
		delivery_method: 0
		fast_delivery: false
		workPeriods: [
			[10, 13]
			[13, 16]
			[16, 19]
			[19, 22]
		]


	validation:
		phone:
			required: true

		company_id:
			required: true

		shop_goods:
			required: true
			minSize: 1

#		delivery_date: (value, attr, model) ->
#			unless value
#				return Backbone.Validation.messages.required
#			minValue =  if @get 'fast_delivery'
#				moment().subtract(1, 'day').unix()
#			else
#				moment().unix()
#			Backbone.Validation.validators.minUnixDate(value, attr, minValue, model)

#		address:
#			required: true

_.extend Iconto.REST.ShopOrder::, Backbone.Validation.mixin

class Iconto.REST.ShopOrderCollection extends Iconto.REST.RESTCollection
	url: 'shop-order'
	model: Iconto.REST.ShopOrder