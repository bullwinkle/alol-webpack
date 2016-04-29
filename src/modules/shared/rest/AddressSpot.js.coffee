class Iconto.REST.AddressSpot extends Iconto.REST.RESTModel
	urlRoot: 'address-spot'
	defaults:
		id: 0
		address_id: 0
		company_id: 0
		legal_id: 0
		description: ''
		full_url: ''
		short_url: ''
		qr_code_link: ''

	validation:
		address_id:
			required: true
			min: 1
		company_id:
			required: true
			min: 1
		description:
			required: true

_.extend Iconto.REST.AddressSpot::, Backbone.Validation.mixin

class Iconto.REST.AddressSpotCollection extends Iconto.REST.RESTCollection
	url: 'address-spot'
	model: Iconto.REST.AddressSpot