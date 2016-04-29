class Iconto.REST.Contact extends Iconto.REST.RESTModel
	@POSITION_TYPE_ADDRESS_EMPLOYEE = POSITION_TYPE_ADDRESS_EMPLOYEE = 0
	@POSITION_TYPE_COMPANY_CONTACT  = POSITION_TYPE_COMPANY_CONTACT  = 1
	@POSITION_TYPE_LEGAL_CEO        = POSITION_TYPE_LEGAL_CEO        = 2
	@POSITION_TYPE_LEGAL_ACCOUNTANT = POSITION_TYPE_LEGAL_ACCOUNTANT = 3
	@POSITION_TYPE_ADDRESS_CONTACT  = POSITION_TYPE_ADDRESS_CONTACT  = 4

	urlRoot: 'contact'
	defaults:
		id: 0
		first_name: ''
		last_name: ''
		email: ''
		phone: ''
		send_sms: false
		position_type: 0
		company_id: 0

	validation:
		first_name:
			required: false
		last_name:
			required: false
		email:
			required: false
			pattern: 'email'
		phone:
			required: true
			pattern: 'phone'

_.extend Iconto.REST.Contact::, Backbone.Validation.mixin

class Iconto.REST.ContactCollection extends Iconto.REST.RESTCollection
	url: 'contact'
	model: Iconto.REST.Contact