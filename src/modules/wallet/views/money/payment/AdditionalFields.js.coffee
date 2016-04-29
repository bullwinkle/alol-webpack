@Iconto.module 'wallet.views.money.payment', (Payment) ->

	class Payment.AmountModel extends Backbone.Model
		defaults:
			amount: undefined

		validation:
			amount:
				required: true
				pattern: 'number'

		serialize: =>
			data = @toJSON()
			data.amount -= 0
			data

	_.extend Payment.AmountModel::, Backbone.Validation.mixin

	class Payment.AdditionalFieldsView extends Marionette.ItemView
		className: 'additional-fields-view'
		template: JST['wallet/templates/money/payment/additional-fields']

		behaviors:
			Epoxy: {}
			Form:
				submit: '[name=submit]'
				events:
					'click': '[name=submit]'

		validated: =>
			model: @model
			fieldsModel: @fieldsModel

		templateHelpers: =>
			fields: @fields

		initialize: =>
			@onFormSubmit = @options.onFormSubmit
			fields = @options.provider.fields or []
			@fields = fields.filter (f) ->
				f.steps.toLowerCase() is "pay"

			parsed = @parseFields(fields)
			@fieldsModel = parsed.fieldsModel
			@events = parsed.events

			@model = new Payment.AmountModel()

		parseFields: (fields) =>
			defaults = {}
			validation = {}
			events = {}
			castToInt = []

			for field in fields
				do (field) =>
					name = field['attribute-name']

					#set default value: undefined
					defaults[name] = undefined

					#store if cast to int needed
					castToInt.push name if field.type is 'INTEGER'

					#init event handlers
					events["input [name=\"#{name}\"]"] =
					events["paste [name=\"#{name}\"]"] =
					events["change [name=\"#{name}\"]"] = (e) =>
						obj = {}
						obj[name] = $(e.currentTarget).val() #inputs
						if field.type is 'MASKED'
							filtered = obj[name].match(/\d/g)
							obj[name] = if filtered then filtered.join('') else ''
						@fieldsModel.set obj, {validate: @setterOptions.validate}

					#init validation
					if field.required
						validation[name] =
							required: true
					if field.type is 'MASKED'
						digits = field.mask.match(/\*/g)
						validation[name] ||= {}
						validation[name].pattern = new RegExp("^\\d{#{digits.length}}$")
					undefined

			events["input [name=amount]"] =
			events["paste [name=amount]"] =
			events["change [name=amount]"] = (e) =>
				value = $(e.currentTarget).val()
				@model.set 'amount', value, {validate: @setterOptions.validate}

			fieldsClass = Backbone.Model.extend
				defaults: defaults
				validation: validation
				serialize: ->
					data = @toJSON()
					data[key] -= 0 for key in castToInt
					data
			_.extend fieldsClass::, Backbone.Validation.mixin

			fieldsModel: new fieldsClass()
			events: events

		onBeforeDestroy: =>
			delete @['onFormSubmit']