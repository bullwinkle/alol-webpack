class Iconto.REST.CashbackTemplate extends Iconto.REST.RESTModel
	urlRoot: 'cashback-template'
	defaults:
		company_id: 0
		title: ''
		description: ''
		images: []
		address_ids: []

		work_time: [
			[
				[0, 86399]
			],
			[
				[0, 86399]
			],
			[
				[0, 86399]
			],
			[
				[0, 86399]
			],
			[
				[0, 86399]
			],
			[
				[0, 86399]
			],
			[
				[0, 86399]
			]
		]
		worktime_from: '00:00'
		worktime_to: '23:59'

		period_from: 0
		period_to: 0

		cashback: ''
		bank_id: 0

		category_ids: []
		terminal_ids: []
		deleted: false
		sale: false
		price: 0

		age: 0
		sex: 0
		payment_count: 0
		payment_sum: 0
		company_payment_count: 0
		company_payment_sum: 0
		first_buy: false
		
		at_birthday: false
		birthday_before: null
		birthday_after: null
		birthday_ages: 0

		is_active: true


	validation:
		title:
			required: true
			minLength: 3
			maxLength: 200

		period_from: (value, attr, model) ->
			minValue = +moment().subtract('days', 1).unix()
			unless value
				return Backbone.Validation.messages.required
			Backbone.Validation.validators.minUnixDate(value, attr, minValue, model)

		period_to: (value, attr, model) ->
			minValue = +moment.unix(model.period_from).unix()
			unless value
				return Backbone.Validation.messages.required
			Backbone.Validation.validators.minUnixDate(value, attr, minValue, model)
		
		work_time:
			required: false
			size: 7

		worktime_from:
			required: false
			pattern: 'time24'

		worktime_to:
			required: false
			pattern: 'time24'

		description:
			maxLength: 1024

		price:
			required: false
			pattern: 'number'
			range: [0, 9999999999]

		birthday_before:
			required: false
			pattern: 'digits'
			min: 0
			max: 365
		birthday_after:
			required: false
			pattern: 'digits'
			min: 0
			max: 365
		birthday_ages:
			required: false
			pattern: 'digits'
			min: 0
			max: 200

		payment_count:
			required: false
			pattern: 'number'
			min: 0
			max: 2147483647

		payment_sum:
			required: false
			pattern: 'number'
			min: 0
			max: 9999999999

		company_payment_count:
			required: false
			pattern: 'number'
			max: 2147483647
			min: 0

		company_payment_sum:
			required: false
			pattern: 'number'
			max: 9999999999
			min: 0

		cashback:
			required: true
			pattern: 'digits'
			min: 1
			max: 100

		address_ids: (value) =>
			if value.length < 1
				return 'Необходимо выбрать хотя бы 1 адрес'

	serialize: (data) =>
		#cast to int
		for key in ['cashback', 'price', 'birthday_before', 'birthday_after', 'birthday_ages', 'payment_count',
		            'payment_sum', 'company_payment_count', 'company_payment_sum']
			data[key] = data[key] - 0 unless _.isUndefined data[key]

		data

_.extend Iconto.REST.CashbackTemplate::, Backbone.Validation.mixin

class Iconto.REST.CashbackTemplateCollection extends Iconto.REST.RESTCollection
	url: 'cashback-template'
	model: Iconto.REST.CashbackTemplate