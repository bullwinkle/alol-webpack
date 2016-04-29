#= require shared/views/autocomplete/BaseAutocomplete

@Iconto.module 'shared.views.autocomplete', (Autocomplete) ->
	class Autocomplete.CityAutocompleteView extends Autocomplete.BaseAutocompleteView
		className: 'city-autocomplete-view'
		collection: new Iconto.REST.CityCollection()
		childViewTemplate: JST['shared/templates/autocomplete/city-autocomplete-item']

		getQuery: ->
			_.extend country_id: @state.get('country_id'), super

		initialize: =>
			super
			@model = new Iconto.REST.City()

			@model.on 'change', =>
				@ui.input.val( @model.get('name') or '')

			@state.set 'placeholder', ''

		onRender: =>
			@ui.input.attr
				name: 'city_id'
				id: 'city'