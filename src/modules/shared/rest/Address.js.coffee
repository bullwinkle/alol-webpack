class Iconto.REST.Address extends Iconto.REST.RESTModel
	@TYPE_ADDRESS         = TYPE_ADDRESS         = 0
	# TODO: Legacy code, remove in bright and wealthy future
	@TYPE_INTERNET_AGENCY = TYPE_INTERNET_AGENCY = 1

	urlRoot: 'address'
	defaults:
		address: ''
		city_id: 0
		category_name: ''
		company_name: ''
		company_id: 0
		country_id: 0
		contact_phone: ''
		latitude: 55.753630
		longitude: 37.620070
		distance: 0
		place_id: ''
		id: 0
		icon_url: ''
		type: 0
		worktime: [[], [], [], [], [], [], []]

	validation:
		address:
			required: true
			minLength: 2
			maxLength: 255
		company_id:
			required: true
			min: 1
		country_id:
			required: true
			min: 1
			msg: 'Выберите страну'
		city_id:
			required: true
			min: 1
			msg: 'Выберите город'
		contact_phone:
			required: true
			pattern: 'phone'
		place_id:
			required: false
		work_time:
			required: false
			size: 7

_.extend Iconto.REST.Address::, Backbone.Validation.mixin

class Iconto.REST.AddressCollection extends Iconto.REST.RESTCollection
	url: 'address'
	model: Iconto.REST.Address