class Iconto.REST.TransactionCompany extends Iconto.REST.RESTModel
	urlRoot: 'transaction-company'

	defaults:

		amount: 0
		cashback: 0
		cashback_percent: 0

		payment_time: 0
		date: 0
		created_at: 0
		updated_at: 0

		currency: ''

		card_id: 0
		user_id: 0
		company_id: 0

		date_from: ''
		date_to: ''

		phone: ''
		address_ids: []

	validation:
		date_from:
			required: false
			maxUnixDate: moment().format('YYYY-MM-DD')
		date_to:
			required: false
			maxUnixDate: moment().format('YYYY-MM-DD')
		phone:
			required: false
			pattern: 'digits'

_.extend Iconto.REST.TransactionCompany::, Backbone.Validation.mixin

class Iconto.REST.TransactionCompanyCollection extends Iconto.REST.RESTCollection
	url: 'transaction-company'
	model: Iconto.REST.TransactionCompany