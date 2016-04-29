class Iconto.REST.Promotion extends Iconto.REST.RESTModel
	urlRoot: 'promotion'
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
		worktime_from: ''
		worktime_to: ''

		period_from: 0
		period_to: 0

		is_active: true

	validation:
		title:
			required: true
			minLength: 3
			maxLength: 200

		period_from: (value, attr, model) ->
			# required : true
			unless value then return Backbone.Validation.messages.required

			# some prepares
			@__fixedPreviousAttributes ||= {}
			@__fixedPreviousAttributes.period_from ||= @_previousAttributes.period_from

			# required variables
			now = moment()
			message
			minValue

			# validating
			if @isNew()
				minValueMoment = now
				minValue = now.subtract('days', 1).unix()
				message = "Минимальное значение #{ minValueMoment.format('DD.MM.YYYY') }"

			else
				nowUnix = now.unix()

				oldValueMoment = moment.unix(@__fixedPreviousAttributes.period_from)
				oldValueMomentUnix = oldValueMoment.unix()

				minValueMoment = moment.unix Math.min oldValueMomentUnix, nowUnix
				minValue = minValueMoment.subtract(1, 'days').unix()

				message = "Минимальное значение #{ minValueMoment.add(1, 'days').format('DD.MM.YYYY') }"


			defultValidationMessage = Backbone.Validation.validators.minUnixDate(value, attr, minValue, model)
			if defultValidationMessage
				return message


		period_to: (value, attr, model) ->
			minValue = +moment.unix(model.period_from).unix()
			unless value then return "Обязательное поле"
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

		address_ids: (value) =>
			if value.length < 1
				return 'Необходимо выбрать хотя бы 1 адрес'


_.extend Iconto.REST.Promotion::, Backbone.Validation.mixin

class Iconto.REST.PromotionCollection extends Iconto.REST.RESTCollection
	url: 'promotion'
	model: Iconto.REST.Promotion