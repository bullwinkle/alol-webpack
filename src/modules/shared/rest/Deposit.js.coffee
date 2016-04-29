class Iconto.REST.Deposit extends Iconto.REST.RESTModel
	urlRoot: 'deposit'
	defaults:
		id: 0
		amount: 0
		hold_amount: 0
		limit_amount: 0
		time: ''

		date_from: ''
		date_to: ''

#	validation:
#		address:
#			required: true
#			minLength: 2
#			maxLength: 255
#		company_id:
#			required: true
#			min: 1
#		name:
#			required: true
#			minLength: 2
#			maxLength: 255
#		postal_code:
#			required: false
#			minLength: 3
#			maxLength: 12
#		phones: (value, attr, computedState) ->
#			#backbone.validation, return true if model is invalid otherwise false
#			if value.length and value[0]
#				return not /^\+?[\d]{3,30}$/.test(value[0])
#			else
#				return false

	validation:
		date_from:
			required: false
			maxUnixDate: moment().format('YYYY-MM-DD')
		date_to:
			required: false
			maxUnixDate: moment().format('YYYY-MM-DD')

_.extend Iconto.REST.Deposit::, Backbone.Validation.mixin

class Iconto.REST.DepositCollection extends Iconto.REST.RESTCollection
	url: 'deposit'
	model: Iconto.REST.Deposit