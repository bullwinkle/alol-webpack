@Iconto.module 'office.views.company', (Company) ->
	class  Company.LegalView extends Marionette.LayoutView
		template: JST['office/templates/company/legal']
		className: 'office-legal-layout mobile-layout'

		behaviors:
			Epoxy: {}
			Layout:
				outlets:
					officeTopbar: JST['office/templates/office-topbar']
			Form:
				submit: '[name=save-button]'
				events:
					click: '[name=save-button]'

		ui:
			inn: '[name=inn]'
			ogrn: '[name=ogrn]'

		regions:
			countryAutocompleteRegion: '#country-autocomplete'
			cityAutocompleteRegion: '#city-autocomplete'

		modelEvents:
			'change:type': ->
				@onTypeChange()

		validated: ->
			model: @model

		serializeData: =>
			_.extend @model.toJSON(), company: @options.company

		initialize: =>
			@model = new Iconto.REST.LegalEntity @options.legal
			@buffer = new Iconto.REST.LegalEntity @options.legal

			legalName = Iconto.shared.helpers.legal.getLegal @options.legal
			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Юридическое лицо'
				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal,
					leadingComma: true)}"
				breadcrumbs: [
					{title: 'Профиль', href: "office/#{@options.companyId}/profile"}
					{title: 'Настройки профиля компании', href: "#"}
				]
				isLoading: false
				officeTopbar:
					currentPage: 'legal'

				inn_is_free: true
				is_ip: @model.get('type') is Iconto.REST.LegalEntity.LEGAL_TYPE_IP

		onRender: =>
			@onTypeChange()

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

		onTypeChange: =>
			isIP = @model.get('type') is Iconto.REST.LegalEntity.LEGAL_TYPE_IP
			@state.set is_ip: isIP
			@model.set kpp: '' if isIP

		onFormSubmit: =>
			fields = (new Iconto.REST.LegalEntity(@buffer.toJSON())).set(@model.toJSON()).changed
			unless _.isEmpty fields
				isNew = @model.isNew()
				fields = _.extend fields, @model.pick('type') if isNew

				@model.save(fields)
				.then (response) =>
					(new Iconto.REST.Company(id: @options.companyId)).save(legal_id: response.id)
					.then =>
						Iconto.shared.views.modals.Alert.show
							title: 'Сохранено'
							message: 'Данные успешно сохранены.'
							onCancel: =>
								# invalidate model, because no deposit id is available
								@model.invalidate()
								Iconto.office.router.navigate "/office/#{@options.companyId}/profile", trigger: true
						@buffer.set @model.toJSON()
				.dispatch(@)
				.catch (error) =>
					console.error error
					error.msg = switch error.status
						when 200005
							'У Вас недостаточно прав для редактирования этих данных.'
						else
							error.msg
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()