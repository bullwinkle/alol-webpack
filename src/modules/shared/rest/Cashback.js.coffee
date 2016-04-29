class Iconto.REST.Cashback extends Iconto.REST.RESTModel

	@OPERATION_TYPE_TRANSACTION = 1
	@OPERATION_TYPE_CASHBACK_WITHDRAW = 2
	@OPERATION_TYPE_CASHBACK_INCOME = 3

	urlRoot: 'cashback'
	defaults:
		id: 0
		user_id: 0
		title: ''
		amount: 0
		fee_amount: 0
		fee_percent: 0
		total: 0
		operation_type: 0
		operation_id: 0
		created_at: 0
		updated_at: 0
		deleted: false
		card_id: 0
		image:
			id: 0
			url: ''

_.extend Iconto.REST.Cashback::, Backbone.Validation.mixin

class Iconto.REST.CashbackCollection extends Iconto.REST.RESTCollection
	url: 'cashback'
	model: Iconto.REST.Cashback
