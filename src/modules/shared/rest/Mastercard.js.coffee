class Iconto.REST.MasterCard extends Iconto.REST.RESTModel
	urlRoot: 'master-card'
	version: '3.0'
	defaults:
		company_id: 0
		user_id: 0
		card_number: ''

	validation:
		card_number:
			required: true
			length: 16
			luhn: true
			msg: 'Неверный номер, проверьте введенное значение'

_.extend Iconto.REST.MasterCard::, Backbone.Validation.mixin

class Iconto.REST.MasterCardCollection extends Iconto.REST.RESTCollection
	url: 'master-card'
	model: Iconto.REST.MasterCard