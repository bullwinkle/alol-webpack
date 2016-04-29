@Iconto.module 'shared.behaviors', (Behaviors) ->

	###
	params:

		bindings: [
			model: 'model'			- name of model, that must exist in view, where to get fields to be synced with
			fields: ['query']		- field from defined model to sync with route query params
		]

	###

	class Behaviors.QueryParamsBinding extends Marionette.Behavior

		getQueryParams = =>
			o = Iconto.shared.helpers.navigation.parseUri()
			delete o.search
			return o.query

		setQueryParams = Iconto.shared.helpers.navigation.setQueryParams

		defaults: bindings: []

		initialize: =>
			@routeQueryParams = getQueryParams()
			for key, val of @routeQueryParams
#				if !val or val is "undefined" then delete @routeQueryParams[key]
				if !@checkValue(val)
					delete @routeQueryParams[key]

		checkValue: (val) =>
			if _.isUndefined(val) or val is "undefined" or _.isNaN(val) or (!_.isUndefined(val.length) && val.length < 1)
				return false
			true

		onRender: (view) =>
			bindings = @options.bindings
			for binding in bindings
				do (binding) =>
					viewModel = @view[binding.model]
					updatableFields = binding.fields
					@updateFields viewModel, updatableFields
					@bindModelFieldsToQueryParams viewModel, updatableFields

		updateFields: (model, fields) =>
			for key, value of @routeQueryParams
				do (key, value) =>
					if key in fields and @checkValue(value)
						model.set key, value

		bindModelFieldsToQueryParams: (model, fields) =>
			for field in fields
				do (field) =>
					event = "change:#{field}"
					@view.listenTo model, event, @setQuery.bind @, field

		setQuery: (field, model, value, options) =>
			setQueryParams field, value, true

