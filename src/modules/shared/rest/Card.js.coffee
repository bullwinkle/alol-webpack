class Iconto.REST.Card extends Iconto.REST.RESTModel
	urlRoot: 'card'

	@TYPE_CREDIT    = TYPE_CREDIT   = 0
	@TYPE_CASH      = TYPE_CASH     = 1
	@TYPE_ICONTO    = TYPE_ICONTO   = 2

	defaults:
		balance: 0
		balance_updated_at: 0
		bank_id: 0
		card_number: ''
		bank_name: ''
		card_tag_id: 0
		created_at: 0
		deleted: false

		is_activated: false
		is_blocked: false
		is_fulfilled: false

		pan_id: 0
		title: ''
		user_id: 0
		type: @TYPE_CREDIT

		system_id: 0

	validation:
		title:
			minLength: 5

	parse: (data) =>
		if data.type is TYPE_CREDIT
			if data.bank_id is -1
				data.type = TYPE_ICONTO
		data

_.extend Iconto.REST.Card::, Backbone.Validation.mixin

class Iconto.REST.CardCollection extends Iconto.REST.RESTCollection
	url: 'card'
	model: Iconto.REST.Card