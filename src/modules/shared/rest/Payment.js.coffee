#= require ./Order

class Iconto.REST.Payment extends Iconto.REST.Task
	urlRoot: 'payment'

	defaults:
		order_id: 0
		card_number: ''
		month: 0
		year: 0
		cardholder_name: ''
		cvc: ''
		card_id: 0
		is_fulfilled: true

		order_type: Iconto.REST.Order.TYPE_UNKNOWN

	validation:
		cvc:
			required: true
			pattern: 'digits'
			minLength: 3
			maxLength: 4
		order_id:
			required: true
		card_number: (value, attr, computedState) ->
			if @get('card_id') and @get('is_fulfilled')
				return undefined
			else if @get('card_id') and @get('order_type') is Iconto.REST.Order.TYPE_CARD_VERIFICATION
				return undefined
			else
				if /^\d{12,19}$/.test(value) and Iconto.shared.helpers.card.validateLuhn( value )
					return undefined
				else
					if value.length < 1
						return Backbone.Validation.messages.required
					else
						return Backbone.Validation.messages.cardNumber

		month: (value, attr, computedState) ->
			if @get('card_id') and @get('is_fulfilled')
				return undefined
			else
				if /^\d{2}$/.test value
					return undefined
				else
					return Backbone.Validation.messages.required
		year: (value, attr, computedState) ->
			if @get('card_id') and @get('is_fulfilled')
				return undefined
			else
				if /^\d{4}$/.test value
					return undefined
				else
					return Backbone.Validation.messages.required
		cardholder_name: (value, attr, computedState) ->
			if @get('card_id') and @get('is_fulfilled')
				return undefined
			else
				if value.length > 0 and value.length <= 512
					return undefined
				else
					return Backbone.Validation.messages.required

#	@TYPE_MONETA_WALLET_PAYMENT = 1
#	@TYPE_NEW_CARD_PAYMENT = 2
#	@TYPE_BOUND_CARD_PAYMENT = 3

	serialize: (data) ->
		if data['is_fulfilled']
			delete data[key] for key in ['card_number', 'month', 'year', 'cardholder_name']
		delete data['is_fulfilled']
		delete data['cvc'] unless data['cvc']
		delete data['card_number'] if data.order_type is Iconto.REST.Order.TYPE_CARD_VERIFICATION
		delete data['order_type']
		data

_.extend Iconto.REST.Payment::, Backbone.Validation.mixin

class Iconto.REST.PaymentCollection extends Iconto.REST.RESTCollection
	url: 'payment'
	model: Iconto.REST.Payment