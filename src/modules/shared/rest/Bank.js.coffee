class Iconto.REST.Bank extends Iconto.REST.RESTModel
	urlRoot: 'bank'

	defaults:
		id: 0
		name: ''
		color: ''
		has_contract: false
		image:
			url: ''

_.extend Iconto.REST.Bank::, Backbone.Validation.mixin

class Iconto.REST.BankCollection extends Iconto.REST.RESTCollection
	url: 'bank'
	model: Iconto.REST.Bank