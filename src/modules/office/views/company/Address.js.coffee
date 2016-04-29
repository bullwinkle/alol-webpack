@Iconto.module 'office.views.company', (Company) ->
	class EmployeeItemView extends Marionette.ItemView
		template: JST['office/templates/company/employee-item']
		className: 'employee'

		ui:
			tips: '.has-tip'

		events:
			'click .ic-cross-circle': 'onEmployeeDeleteButtonClick'
			'change input[type=checkbox]': 'onCheckboxChange'
			'click @ui.tips': 'onTipsClick'

		initialize: =>
			model = @model.toJSON()
			if not model.first_name and not model.last_name
				@model.set first_name: 'Аноним #' + @model.get('user_id')

		onEmployeeDeleteButtonClick: =>
			@trigger 'employee:delete', @model

		onCheckboxChange: (e) =>
			@model.set 'send_sms', $(e.currentTarget).get(0).checked
			@model.save(send_sms: @model.get('send_sms'))
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onTipsClick: (e) =>
			$tip = $(e.currentTarget)
			Iconto.shared.views.modals.Alert.show
				message: $tip.data('message')

	class EmployeeCollectionView extends Marionette.CollectionView
		childView: EmployeeItemView

		onChildviewEmployeeDelete: (view, model) =>
			Iconto.shared.views.modals.Confirm.show
				title: 'Удаление сотрудника'
				message: 'Вы уверены, что хотите удалить сотрудника?'
				onSubmit: =>
					# model.destroy() removes model from collection immediately
					(new Iconto.REST.Contact(id: model.get('id'))).destroy()
					.then =>
						@collection.remove model
					.catch (error) =>
						console.error error
						Iconto.shared.views.modals.ErrorAlert.show error
					.done()

	class AddressItemView extends Marionette.ItemView
		template: JST['office/templates/new/address-item']
		className: 'flexbox'

	class AddressesCollectionView extends Marionette.CollectionView
		childView: AddressItemView

	class Company.AddressView extends Marionette.LayoutView
		template: JST['office/templates/company/address']
		className: 'company-address-layout mobile-layout'

		behaviors:
			Epoxy: {}
			Layout: {}
			Form:
				submit: '[name=save-button]'
				events:
					click: '[name=save-button]'

		ui:
			cityLabel: 'label[for=city]'
			position: '.position'

			countrySelect: '[name=country_id]'
			citySelect: '[name=city_id]'

			saveButton: '[name=save-button]'
			deleteButton: '[name=delete-button]'

			addAddressManuallyButton: '[name=add-address-manually-button]'
			addressInputs: '.addresses-inputs'
			addressInputTemplate: '.addresses-input-template'
			saveAddressesButton: '[name=save-addresses-button]'

			countryInput: '[name=country-name]'
			cityInput: '[name=city-name]'
			cancelButton: '[name=cancel-button]'

		events:
		#			'click @ui.saveButton': 'onFormSubmit'
			'click @ui.deleteButton': 'onAddressDeleteButtonClick'
			'click @ui.cancelButton': 'onCancelButtonClick'
			'click @ui.addAddressManuallyButton': 'onAddAddressManuallyButtonClick'
			'click @ui.saveAddressesButton': 'onSaveAddressesButtonClick'

		regions:
			countryAutocompleteRegion: '#country-autocomplete'
			cityAutocompleteRegion: '#city-autocomplete'
			addressesRegion: '.addresses'

		validated: =>
			model: @model

		initialize: =>
			@model = new Iconto.REST.Address
				id: (@options.addressId || 0)
				company_id: @options.company.id

			if @model.isNew()
				#				for k, v of @model.validation
				#					console.log k, v
				@model.validation.contact_phone.required = false

			@cityCollection = new Iconto.REST.CityCollection()
			@addressesCollection = new Iconto.REST.AddressCollection()

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Новый адрес' unless @model.get('id')
				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal,
					leadingComma: true)}"
				breadcrumbs: [
					{title: 'Профиль', href: "office/#{@options.companyId}/profile"}
					{title: 'Настройки профиля компании', href: "office/#{@options.companyId}/addresses"}
					{title: (if @model.isNew() then 'Новый адрес' else 'Адрес'), href: "#"}
				]

				isNew: @model.isNew()
				phone: ''
				employee_phone: ''
				location: ''

				addresses: []
				countries: []
				cities: []

				loading: false
				gotInternetAgency: false

			@listenTo @state,
				'change:phone': (state, phone) =>
					if phone.trim().length > 0
						@model.set 'contact_phone', "7#{Iconto.shared.helpers.phone.parse(phone)}", validate: true
					else
						@model.set 'contact_phone', '', validate: true

			@listenTo @model,
				'change:country_id': @onCountryIdChange
				'change:city_id': @onCityIdChange

		onRender: =>
			@addressesCollection.fetchAll(company_id: @options.company.id)
			.then (addresses) =>
				@state.set 'addresses', addresses
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

			(new Iconto.REST.CountryCollection()).fetchAll()
			.then (countries) =>
				countries = _.sortBy countries, (country) ->
					country.name
				countries = @moveToTop(countries, ['Россия'])
				countries = _.map countries, (country) ->
					label: country.name, value: country.id
				@state.set
					countries: countries
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set isLoading: false

			unless @model.isNew()
				# edit address
				@model.fetch()
				.then (model) =>
					@model.set(model, silent: true)
					@buffer = new Iconto.REST.Address @model.toJSON()

					@state.set
						topbarTitle: @model.get('address') or 'Интернет-представительство'
						phone: @model.get('contact_phone').substr(1, 10)

					# set country name
					if @model.get('country_id')
						(new Iconto.REST.Country(id: @model.get('country_id'))).fetch()
						.then (country) =>
							@ui.countryInput.val country.name
						.done()

					if @model.get('city_id')
						(new Iconto.REST.City(id: @model.get('city_id'))).fetch()
						.then (city) =>
							@ui.cityInput.val city.name
						.done()
				.done()

		onAddressDeleteButtonClick: =>
			Iconto.shared.views.modals.Confirm.show
				title: 'Удаление адреса'
				message: 'Вы уверены, что хотите удалить адрес?'
				onSubmit: =>
					@model.destroy()
					.then =>
						Iconto.office.router.navigate "/office/#{@model.get('company_id')}/addresses", trigger: true
					.catch (error) =>
						console.error error
						error.msg = switch(error.status)
							when 103121 then 'Чтобы удалить адрес, вам необходимо изменить точки обратной связи, в которых он указан.'
							when 103122 then 'Чтобы удалить адрес, вам необходимо изменить шаблоны CashBack, в которых он указан.'
							when 103123 then 'Чтобы удалить адрес, вам необходимо изменить шаблоны CashBack и точки обратной связи, в которых он указан.'
							when 103104 then 'У компании должен быть хотя бы один адрес.'
							else
								error.msg
						Iconto.shared.views.modals.ErrorAlert.show error
						console.log error
					.done()

		onCancelButtonClick: =>
			Iconto.office.router.navigate "/office/#{@options.companyId}/addresses", trigger: true

		onSaveAddressesButtonClick: =>
			address = new Iconto.REST.Address()
			params =
				address: $('.addresses-input-item input', @ui.addAddressBlock).val()
				company_id: @options.company.id
				country_id: @model.get('country_id')
				city_id: @model.get('city_id')
				contact_phone: @model.get('contact_phone')

			return false unless (new Iconto.REST.Address(params)).isValid(true)

			address.save(params)
			.then =>
				Iconto.office.router.navigate "/office/#{@options.companyId}/addresses", trigger: true
			.catch (error) =>
				console.log error
				error.msg = switch error.status
					when 208120
						'Минимальная длина адреса - 3 символа'
					else
						error.msg
				Iconto.shared.views.modals.ErrorAlert.show error


		#			addressIds = @$('.addresses input[type=checkbox]:checked').map(->
		#				return +@value if +@value
		#				return @value
		#			).get()
		#
		#			addresses = _.compact $('.addresses-input-item input', @ui.addAddressBlock).map(->
		#				return @value
		#			).get()
		#
		#			if (
		#				+@model.get('type') is Iconto.REST.Address.TYPE_ADDRESS and (@model.get('country_id') and @model.get('city_id') and (addressIds.length > 0 or addresses.length > 0))
		#			)
		#				@state.set isLoading: true

		#				Q.fcall =>
		#					if addressIds.length > 0
		#						(new Iconto.REST.AddressCollection()).fetchByIds(addressIds)
		#						.then (addresses) =>
		#							addresses
		#					else
		#						[]
		#				.then (_addresses) =>
		#					addressPromises = []
		#					if addressIds.length > 0
		#						for addressId in addressIds
		#							address = _.find _addresses, (a) ->
		#								a.id is addressId
		#							params =
		#								company_id: @options.companyId
		#								place_id: addressId
		#								address: address.address
		#								country_id: @model.get('country_id')
		#								city_id: @model.get('city_id')
		#							addressPromises.push (new Iconto.REST.Address()).save(params)
		#					if addresses.length > 0
		#						for address in addresses
		#							params =
		#								company_id: @options.companyId
		#								address: address
		#								country_id: @model.get('country_id')
		#								city_id: @model.get('city_id')
		#							addressPromises.push (new Iconto.REST.Address()).save(params)
		#					else
		#						params =
		#							type: +@model.get('type')
		#							company_id: @options.companyId
		#							country_id: @model.get('country_id')
		#							city_id: @model.get('city_id')
		#						addressPromises.push (new Iconto.REST.Address()).save(params)
		#
		#					Q.all(addressPromises)
		#				.then =>
		#					Iconto.office.router.navigate "/office/#{@options.companyId}/addresses", trigger: true
		#				.dispatch(@)
		#				.catch (error) =>
		#					console.error error
		#					Iconto.shared.views.modals.ErrorAlert.show error
		#					@state.set isLoading: false
		#				.done()

		onFormSubmit: =>
			# update address
			fields = (new Iconto.REST.Address(@buffer.toJSON())).set(@model.toJSON()).changed
			if not _.isEmpty fields
				@model.save(fields)
				.then =>
					Iconto.shared.views.modals.Alert.show
						title: "Сохранено"
						message: 'Данные адреса успешно сохранены.'
						onCancel: =>
							Iconto.office.router.navigate "/office/#{@model.get('company_id')}/addresses", trigger: true
				.catch (error) =>
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()

		onAddAddressManuallyButtonClick: =>
			if @$('.addresses-input-item').length < 1 and @model.get('country_id') and @model.get('city_id')
				$el = @ui.addressInputTemplate.clone().removeClass('addresses-input-template').addClass('addresses-input-item')
				@ui.addressInputs.append $el

		moveToTop: (array, values) =>
			# move to top
			tempArray = _.filter array, (city) ->
				_.contains values, city.name
			tempArray = _.sortBy tempArray, (city) ->
				city.name
			array = _.without array, tempArray
			array.unshift tempArray
			array = _.flatten array, true

		onCountryIdChange: (model, value) =>
			# reset variables
			@state.set cities: []
			@model.set city_id: 0
			@addressesRegion.currentView?.collection.reset()

			@ui.citySelect
			.selectOrDie('update')
			.parent('.sod_select')
			.addClass('is-loading')

			@cityPromise?.cancel()

			#@cityPromise = (new Iconto.REST.CityCollection()).fetchAll(country_id: value)
			@cityPromise = (new Iconto.REST.CityCollection()).fetchIds(country_id: value)
			.then (ids) =>
				ids = ids.slice(0, 255)
				@cityCollection.fetchByIds(ids)
			.then (cities) =>
				cities = _.sortBy cities, (city) ->
					city.name
				cities = @moveToTop(cities, ['Москва', 'Санкт-Петербург'])
				cities = _.map cities, (city) ->
					label: city.name, value: city.id

				@state.set cities: cities

				@ui.citySelect
				.selectOrDie('update')
				.parent('.sod_select')
				.removeClass('is-loading')
			.dispatch(@)

			@cityPromise
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onCityIdChange: (model, value) =>
			return false unless value

			@onAddAddressManuallyButtonClick()

#			@state.set loading: true
#			@addressesRegion.currentView?.collection.reset()
#
#			cityName = @cityCollection.find((city) ->
#				city.get('id') == value)?.get('name')
#			companyName = @options.company.name
#
#			params =
#				query: companyName
#				limit: 1000
#				offset: 0
#				location: cityName
#
#			@addressesCollection.fetchAll(params)
#			.then =>
#				filteredAddresses = @addressesCollection.filter (model) =>
#					!model.get('company_id')
#				filteredAddressesCollection = new Iconto.REST.AddressCollection(filteredAddresses)
#				if filteredAddressesCollection.length > 0
#					@state.set loading: false
#					addressesCollectionView = new AddressesCollectionView(collection: filteredAddressesCollection)
#					@addressesRegion.show addressesCollectionView
#				else
#					@state.set loading: false

#
#			.dispatch(@)
#			.catch (error) =>
#				console.error error
#				@state.set loading: false
#				console.log error
#			.done()