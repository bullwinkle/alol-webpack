class Iconto.REST.Transaction extends Iconto.REST.RESTModel
	urlRoot: 'transaction'

	@SOURCE_TYPE_UNKNOWN       = 0
	@SOURCE_TYPE_ACQUIRER      = 1
	@SOURCE_TYPE_EMITENT       = 2
	@SOURCE_TYPE_IIKO          = 3
	@SOURCE_TYPE_USER          = 4
	@SOURCE_TYPE_SMS           = 5
	@SOURCE_TYPE_EXTERNAL_APP  = 6
	@SOURCE_TYPE_TEST          = 7
	@SOURCE_TYPE_COMPANY       = 8

	defaults:
		amount: "0.00" 		# show
		payment_time: "" 	# show
		cashback: "0.00" 	# show
		card_number: ""
		user_id: 0
		card_id: 0
		terminal_id: 0
		currency_id: 0
		user_category_id: 0
		created_at: 0
		status: 0
		type: 0
		accepted_at: ""
		bank_id: 0
		address_id: 0
		company_id: 0
		has_cashback: false
		cashback_percent: 0
		cashback_template_id: 0
		external_id: ""
		terminal_name: ""
		company_category_id: 0
		returned: false
		returned_cashback: "0.00"
		returned_amount: "0.00"
		merchant_external_id: 0
		rrn: ""
		bank_emitent_id: 0
		acquirer_id: 0
		cashback_type: 0
		affected_amount: "0.00"
		source_type: 0
		with_cashback: false
		description: ""
		deleted: false
		hidden: 0
		cashback_template_ids: []
		parent_id: 0
		source_id: 0
		discount: "0.00"

	validation:
		date_from:
			required: true
			min: 1
			msg: 'Неверная дата'
		date_to: (value, fieldName, model) =>
			msg = 'Неверная дата'

			if !value or value < 1 or value < model.date_from
				return msg

		card_number:
			required: true
			luhn: true



class Iconto.REST.TransactionCollection extends Iconto.REST.RESTCollection
	url: 'transaction'