class Iconto.REST.CustomerDiscountCard extends Iconto.REST.RESTModel
	urlRoot: 'customer-discountcard'

	@STATUS_INACTIVE = 1
	@STATUS_PENDING = 2
	@STATUS_ACTIVE = 3

	defaults:
		user_id: 0
		discountcard_id: 0
		company_id: 0
		address_ids: []
		accepted_everywhere: true
		excluded_address_ids: []
		percent: 0
		balance: 0
		external_id: 0
		deleted: false
		created_at: 0
		title: ''
		description: ''
		currency_name: ''

_.extend Iconto.REST.CustomerDiscountCard::, Backbone.Validation.mixin

class Iconto.REST.CustomerDiscountCardCollection extends Iconto.REST.RESTCollection
	url: 'customer-discountcard'
	model: Iconto.REST.CustomerDiscountCard