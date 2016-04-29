class Iconto.REST.Offer extends Iconto.REST.RESTModel
	@TYPE_USER     = TYPE_USER = 1
	@TYPE_MERCHANT = TYPE_MERCHANT = 2

	urlRoot: "offer"

	defaults:
		id: 0
		offer_text: ''
		type: TYPE_USER
		parent_id: 0
		created_at: 0
		deleted: false
		filters: []
