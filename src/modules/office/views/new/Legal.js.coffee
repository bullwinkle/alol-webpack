@Iconto.module 'office.views.new', (New) ->
	class New.LegalView extends Marionette.LayoutView
		template: JST['office/templates/new/legal']
		className: 'legal-view mobile-layout'

		behaviors:
			Epoxy: {}
			Layout: {}
			Form:
				submit: '[name=continue-button]'
				events:
					click: '[name=continue-button]'

		regions:
			countryAutocompleteRegion: '#country-autocomplete'
			cityAutocompleteRegion: '#city-autocomplete'

		ui:
			backButton: '[name=back-button]'
			skipButton: '[name=skip-button]'
			continueButton: '[name=continue-button]'
			continueNoValidationButton: '[name=continue-no-validation-button]'

			form: '.form'
			legalSelect: 'select[name=legal_id]'
			typeSelect: 'select[name=type]'
			addLegalButton: '.add-legal'

		events:
			'click @ui.backButton': 'onBackButtonClick'
			'click @ui.continueNoValidationButton': 'onContinueButtonClick'
			'click @ui.skipButton': 'onSkipButtonClick'
			'click @ui.addLegalButton': 'onAddLegalButtonClick'

		serializeData: =>
			@model.toJSON()
			@state.toJSON()

		validated: =>
			model: @model

		initialize: =>
			@model = @options.legal
			@buffer = new Iconto.REST.LegalEntity @options.legal.toJSON()

#			Backbone.Validation.bind @

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Заявка на управление компанией'
				isLoading: false
				stepIcons: @options.stepIcons
				step: 4

				creatingFromScratch: 0
				legalId: 0
				legals: []
				loading: true

			@listenTo @state, 'change:creatingFromScratch', (model, value) =>
				# detect class name
				className = if value then 'state-3' else 'state-2'

				# clear classes and set class name
				@ui.form.removeClass('state-1 state-2 state-3').addClass(className)

				# select legal type
				@ui.typeSelect.selectOrDie('select', @model.get('type')) if @model.get('name') or @model.get('inn')

			@listenTo @state, 'change:legalId', (model, value) =>
				# set legal id if selected
				@model.set id: value - 0

		onBackButtonClick: =>
			# go back to image view
			@trigger 'transition:back'

		onFormSubmit: =>
			# remove model id if has any
			@model.set id: 0
			@trigger 'transition:submitRequest'

		onSkipButtonClick: =>
			# reset all legal fields with defaults, even id
			@model.clear()
			@model.set (new Iconto.REST.LegalEntity()).toJSON()

			# go to final
			@trigger 'transition:submitRequest'

		onContinueButtonClick: =>
			if @state.get('creatingFromScratch')
				# explicitly set id to 0
				@model.set id: 0

				# validate model
				@trigger 'transition:submitRequest' if @model.isValid(true)

			else
				# clear all fields except id
				id = @model.get('id')
				@model.set (new Iconto.REST.LegalEntity()).toJSON()
				@model.set id: id

				# check if legal selected
				@trigger 'transition:submitRequest' if @model.get('id')

		onRender: =>


			countryAutocompleteView = new Iconto.shared.views.autocomplete.CountryAutocompleteView()
			cityAutocompleteView = new Iconto.shared.views.autocomplete.CityAutocompleteView()

			countryAutocompleteView.on 'autocomplete:selected', (country) =>
				if country.id isnt @model.get('country_id')
					cityAutocompleteView.disable()
					@model.set 'country_id', country.id
					@model.validate 'country_id'

					cityAutocompleteView.update country_id: country.id
					cityAutocompleteView.on 'autocomplete:selected', (city) =>
						@model.set 'city_id', city.id
						@model.validate 'city_id'

					cityAutocompleteView.on 'autocomplete:query', (query) =>
						@model.set 'city_id', 0

					cityAutocompleteView.enable()

			countryAutocompleteView.on 'autocomplete:query', =>
				cityAutocompleteView.disable()
				@model.set {country_id: 0, city_id: 0}

			@countryAutocompleteRegion.show countryAutocompleteView
			@cityAutocompleteRegion.show cityAutocompleteView
			cityAutocompleteView.disable()

			unless @model.isNew()
				if @model.get('country_id')
					(new Iconto.REST.Country(id: @model.get('country_id'))).fetch()
					.then (country) =>
						countryAutocompleteView.ui.input.val(country.name)
					.done()
				else
					@countryAutocompleteRegion.show countryAutocompleteView

				cityAutocompleteView = new Iconto.shared.views.autocomplete.CityAutocompleteView country_id: @model.get('country_id')
				cityAutocompleteView.on 'autocomplete:query', (query) =>
					@model.set 'city_id', 0
				cityAutocompleteView.on 'autocomplete:selected', (city) =>
					@model.set 'city_id', city.id

				# set city name
				if @model.get('city_id')
					(new Iconto.REST.City(id: @model.get('city_id'))).fetch()
					.then (city) =>
						@cityAutocompleteRegion.show cityAutocompleteView
						cityAutocompleteView.ui.input.val(city.name)
					.done()
				else
					@cityAutocompleteRegion.show cityAutocompleteView


			# get user legals
			(new Iconto.REST.LegalEntityCollection()).fetchAll()
			.then (legals) =>

				# sort legals
				legals = _.sortBy legals, (legal) ->
					legal.name.toLowerCase()

				# prepate legals for Epoxy options
				legals = _.map legals, (legal) ->
					label: legal.name, value: legal.id

				# show legals
				@state.set legals: legals

				# show type
				@ui.typeSelect.selectOrDie('select', @model.get('type'))

				# state-1: no legals, from cratch
				# state-2: has legals, from id
				# state-3: has legals, from cratch

				# general state class
				stateClass = ''

				# first time on this page or not, true by default
				firstTime = true
				# if model has fields or model has id
				firstTime = false if @model.get('name') or @model.get('inn') or @model.get('id')

				if legals.length is 0
					# always state-1 if no legals
					stateClass = 'state-1'

					# select company type, if first time
					@ui.typeSelect.selectOrDie('select', @model.get('type')) unless firstTime

					# set radio buttons
					@state.set creatingFromScratch: 1

				else
					if firstTime
						# set class
						stateClass = 'state-2'

					else
						if @model.get('id')
							# set class
							stateClass = 'state-2'

							# select previously selected legal
							@ui.legalSelect.selectOrDie('select', @model.get('id'))

						else
							# set class
							stateClass = 'state-3'

							# set radio buttons
							@state.set creatingFromScratch: 1

							# select legal type
							@ui.typeSelect.selectOrDie('select', @model.get('type'))

				# set state class
				@ui.form.addClass stateClass

				# show view
				@state.set loading: false

			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()