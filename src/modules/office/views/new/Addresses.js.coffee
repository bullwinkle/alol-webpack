@Iconto.module 'office.views.new', (New) ->
	class New.AddressesView extends Marionette.ItemView
		template: JST['office/templates/new/addresses']
		className: 'addresses-view mobile-layout'

		behaviors:
			Epoxy: {}
			Layout: {}

		ui:
			countrySelect: '[name=country_id]'
			citySelect: '[name=city_id]'
			addAddress: '.add-address'
			addressInputsBlock: '.address-inputs-block'

			backButton: '[name=back-button]'
			continueButton: '[name=continue-button]'

		events:
			'click @ui.addAddress': 'addAddressBlock'

			'click @ui.backButton': 'onBackButtonClick'
			'click @ui.continueButton': 'onContinueButtonClick'

		serializeData: =>
			@state.toJSON()

		initialize: =>
			@model = @options.company

			# from layout
			@addressesData = @options.addressesData

			# city resource
			@cityCollection = new Iconto.REST.CityCollection()

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Заявка на управление компанией'
				isLoading: false
				stepIcons: @options.stepIcons
				step: 2

				countries: []
				countryId: 0
				cities: []
				cityId: 0

			@listenTo @state,
				'change:countryId': @onCountryIdChange
				'change:cityId': @onCityIdChange

		onRender: =>
			# get countries
			(new Iconto.REST.CountryCollection()).fetchAll()
			.then (countries) =>

				# sort countries by name
				countries = _.sortBy countries, (country) -> country.name

				# move top Russia
				countries = @moveToTop(countries, ['Россия'])

				# map countries for Epoxy options
				countries = _.map countries, (country) -> label: country.name, value: country.id

				# set countries
				@state.set countries: countries

				# select country id if available
				if @addressesData.countryId

					# select country if has any
					@ui.countrySelect.selectOrDie('select', @addressesData.countryId)

					# set country id
					@state.set countryId: @addressesData.countryId
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onCountryIdChange: (model, countryId) =>
			# set global country id
			@addressesData.countryId = countryId

			# reset cities
			@state.set
				cities: []
				cityId: 0

			# set loading class to cities select
			@ui.citySelect.selectOrDie('update').parent('.sod_select').addClass('is-loading')

			# cancel promise execution if any is running
			@cityPromise?.cancel()

			# get cities by country
			@cityPromise = (new Iconto.REST.CityCollection()).fetchIds(country_id: countryId)
			.then (cityIds) =>
				# TODO: change to autocomplete
				cityIds = cityIds.slice(0, 255)

				# request cities in short format
				@cityCollection.fetch(ids: cityIds, format: 'short')

			.then (cities) =>

				# sort by name
				cities = _.sortBy cities, (city) -> city.name

				# move top main cities
				cities = @moveToTop(cities, ['Москва', 'Санкт-Петербург'])

				# prepare for Expoxy options
				cities = _.map cities, (city) -> label: city.name, value: city.id

				# set cities
				@state.set cities: cities

				# remove loading class from cities select
				@ui.citySelect.selectOrDie('update').parent('.sod_select').removeClass('is-loading')

				# select city if has any
				@ui.citySelect.selectOrDie('select', @addressesData.cityId) if @addressesData.cityId
			.dispatch(@)

			# WAT. Cancellable works so.
			@cityPromise
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onCityIdChange: (model, cityId) =>
			if cityId is 0
				# empty addresses block
				@ui.addressInputsBlock.empty()
			else
				# set global city id
				@addressesData.cityId = cityId

				# for initial render
				if @addressesData.addresses.length > 0

					# loop through all addresses
					for address in @addressesData.addresses

						# get address template
						$newAddressNode = @$('.template .new-address').clone()

						# populate template and append
						@ui.addressInputsBlock.append($newAddressNode.find('input').val(address).end())
				else
					# add address by default
					@addAddressBlock()

		onBackButtonClick: =>
			@trigger 'transition:back'

		onContinueButtonClick: =>
			# get filled addresses
			addresses = _.compact @$('.address-inputs-block .new-address input').map(-> return @value).get()
			if addresses.length > 0
				# set addresses
				@addressesData.addresses = addresses

				# go to next view
				@trigger 'transition:image'
			else
				Iconto.shared.views.modals.Alert.show
					message: 'Добавьте хотя бы один адрес'

		moveToTop: (array, values) =>
			# find items in array
			itemsToMove = _.filter array, (city) ->
				_.contains values, city.name

			# remove items from array
			for itemToMove in itemsToMove
				array = _.without array, itemToMove

			# reverse for unshift
			itemsToMove.reverse()

			# unshift values
			for shiftItem in itemsToMove
				array.unshift shiftItem

			array

		addAddressBlock: =>
			# return if no city selected
			return unless @state.get('cityId')

			# return if there is empty input
			vals = @$('.address-inputs-block .new-address input').map(-> @value)
			return if vals.length isnt _.compact(vals).length

			# check address inputs max amount (max = 5)
			return if @$('.address-inputs-block .new-address').length >= 5

			# get address template
			$newAddressNode = @$('.template .new-address').clone()

			# append to address list
			@ui.addressInputsBlock.append($newAddressNode.clone())