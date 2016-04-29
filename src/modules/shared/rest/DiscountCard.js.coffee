class Iconto.REST.DiscountCard extends Iconto.REST.RESTModel
	urlRoot: 'discountcard'

	@SEX_MALE     = 1
	@SEX_FEMALE   = 2
	@SEX_UNKNOWN  = 0

	@STATUS_UNKNOWN     = 0
	@STATUS_PENDING     = 1
	@STATUS_CANCELLED   = 2
	@STATUS_APPROVED    = 3

	@TYPE_UNKNOWN           = TYPE_UNKNOWN            = 0
	@TYPE_WISH              = TYPE_WISH               = 1
	@TYPE_DISCOUNT_CARD     = TYPE_DISCOUNT_CARD      = 2
	@TYPE_PERSONAL_CASHBACK = TYPE_PERSONAL_CASHBACK  = 3

	defaults:
		card_number: ''
		first_name: ''
		second_name: ''
		middle_name: ''
		phone: ''
		email: ''
		title: ''
		status: @STATUS_UNKNOWN
		created_at: 0
		updated_at: 0
		sex: @SEX_UNKNOWN
		discount: 0
		company_id: 0
		comment: ''

		type: @TYPE_UNKNOWN

	validation:
		discount:
			required: false
			pattern: 'digits'
			min: 0
			max: 99
		company_id:
			required: true

	initialize: =>
		super

	serialize: (data) =>
		for key in ['discount']
			data[key] = data[key] - 0 unless _.isUndefined(data[key])
		data

	fetch: =>
		super
		.then (model) =>
				data = @toJSON()
				type =
					if data.status is data.status is Iconto.REST.DiscountCard.STATUS_PENDING
						if data.discount
							TYPE_DISCOUNT_CARD
						else
							TYPE_WISH
					else
						TYPE_PERSONAL_CASHBACK
				@set 'type', type
				model


_.extend Iconto.REST.DiscountCard::, Backbone.Validation.mixin

class Iconto.REST.DiscountCardCollection extends Iconto.REST.RESTCollection
	url: 'discountcard'
	model: Iconto.REST.DiscountCard

	sortByStatusAndUpdatedAt: => #first go pending cards sorted by updated_at, then - resolved (non-pending status)
		pending = @filter (m) ->
			m.get('status') is Iconto.REST.DiscountCard.STATUS_PENDING
		resolved = @filter (m) ->
			status = m.get('status')
			status isnt Iconto.REST.DiscountCard.STATUS_PENDING and status isnt Iconto.REST.STATUS_UNKNOWN
#		cancelled = @filter (m) ->
#			m.get('status') is Iconto.REST.DiscountCard.STATUS_CANCELLED
#		approved = @filter (m) ->
#			m.get('status') is Iconto.REST.DiscountCard.STATUS_APPROVED

		iterator = (m) ->
			-(m.get('updated_at') or m.get('created_at'))

		result = _.sortBy pending, iterator
#		result.push m for m in _.sortBy cancelled, iterator
#		result.push m for m in _.sortBy approved, iterator
		result.push m for m in _.sortBy resolved, iterator

		result