#= require shared/views/autocomplete/BaseAutocomplete

@Iconto.module 'shared.views.autocomplete', (Autocomplete) ->
	class Autocomplete.CountryAutocompleteView extends Autocomplete.BaseAutocompleteView
		className: 'country-autocomplete-view'
		collection: new Iconto.REST.CountryCollection()
		childViewTemplate: JST['shared/templates/autocomplete/country-autocomplete-item']

		initialize: =>
			super
			@model = new Iconto.REST.Country()

			@model.on 'change', =>
				@ui.input.val( @model.get('name') or '' )

			@state.set 'placeholder', ''

		onRender: =>
			@ui.input.attr
				name: 'country_id'
				id: 'country'