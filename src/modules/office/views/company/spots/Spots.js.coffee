@Iconto.module 'office.views.company', (Company) ->
	class AddressSpot extends Marionette.ItemView
		template: JST['office/templates/company/spots/spot-item']
		className: 'spot-item flexbox'

		templateHelpers: =>
			url: =>
				model = @model.toJSON()
				url = model.short_url or model.full_url
				return "https:#{url}" if url

				env = Iconto.shared.helpers.environment()
				env = ".#{env}" if env
				"https://#{@options.settings.domain}#{env}.iconto.net/feedback/#{model.id}"

			address: =>
				model = @model.toJSON()
				@options.addresses ||= {}
				address = _.find @options.addresses, (address) ->
					address.id is model.address_id
				_.get address, 'address', '–'

		triggers:
			'click .spot-delete .ic-cross-circle': 'spot:delete'

		ui:
			description: '.description'
			descriptionInput: '[name=description]'
			editButton: 'i.ic-pencil-black'
			cancelButton: '.cancel-button'
			saveButton: '.save-button'

		events:
			'click @ui.editButton': 'onEditButtonClick'
			'click @ui.cancelButton': 'onCancelButtonClick'
			'click @ui.saveButton': 'onSaveButtonClick'

		onEditButtonClick: =>
			@ui.descriptionInput.val @model.get('description')
			$('.spot-item').removeClass('edit')
			@$el.toggleClass('edit')

		onSaveButtonClick: =>
			value = @ui.descriptionInput.val().trim()
			@$el.removeClass('edit')
			@model.save(description: value)
			.then =>
				@ui.description.text value
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error

		onCancelButtonClick: =>
			@$el.removeClass('edit')

	class Company.SpotsView extends Marionette.CompositeView #Iconto.shared.views.infinite.BaseInfiniteCompositeView
		template: JST['office/templates/company/spots/spots']
		className: 'profile-spots-layout mobile-layout'
		childView: AddressSpot
		childViewContainer: '.address-spots-region'

		behaviors:
			Epoxy: {}
			Layout: {}

		ui:
			topbarLeftButton: '.topbar-region .left-small'
			topbarRightButton: '.topbar-region .right-small'
			spotDescription: '[name=spot_description]'
			select: 'select[name=address-id]'
			saveButton: '[name=save-button]'
			cancelButton: '[name=cancel-button]'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'
			'click [name=save-button]:not(.is-loading)': 'onSaveButtonClick'
			'click @ui.cancelButton': 'onCancelButtonClick'

		childViewOptions: =>
			addresses: @companyAddressesCollection.toJSON()
			settings: @companySettings.toJSON()

		bindingSources: =>
			spot: @spot

		collectionEvents: =>
			'add remove reset': (model, collection, options) =>
				topbarSubtitle = Iconto.shared.helpers.declension(collection.length, ['точка', 'точки', 'точек'])
				@state.set
					topbarSubtitle: "#{collection.length} #{topbarSubtitle}"
					spot_count: collection.length

		initialize: =>
			@model = new Iconto.REST.Company(id: @options.companyId)
			@collection = new Iconto.REST.AddressSpotCollection()
			@collection.comparator = (m1, m2) ->
				return -1 if m1.get('created_at') > m2.get('created_at')
				return 1 if m1.get('created_at') < m2.get('created_at')
				return 0

			@spot = new Iconto.REST.AddressSpot(company_id: @options.companyId)

			@companyAddressesCollection = new Iconto.REST.AddressCollection()
			@companySettings = new Iconto.REST.CompanySettings(id: @options.companyId)

			@MODE =
				SPOT_LIST: 1
				SPOT_ADD: 2

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Точки обратной связи'
				topbarSubtitle: '0 точек'
				topbarRightButtonSpanClass: 'ic-plus-circle'

				spot_count: 0
				hasAddresses: false
				hasDomain: false
				mode: @MODE.SPOT_LIST
				addresses: []

		onRender: =>
			# check if we can create spots
			# we must have at least one address and domain specified
			companyAddressesPromise = @companyAddressesCollection.fetchAll(company_id: @options.companyId)
			companySettingsPromise = @companySettings.fetch()

			Promise.all([companyAddressesPromise, companySettingsPromise])
			.spread (addresses, settings) =>
				@state.set
					hasDomain: not _.isEmpty(settings.domain)
					hasAddresses: addresses.length > 0
					addresses: addresses
				if addresses.length > 0 and settings.domain
					# we have at least one address and domain specified
					@collection.fetchAll(company_id: @options.companyId)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.then =>
				@state.set isLoading: false
				@ui.select.selectOrDie()

		onTopbarRightButtonClick: =>
			if @state.get('hasAddresses') and @state.get('hasDomain')
				@state.set mode: if @state.get('mode') is @MODE.SPOT_LIST then @MODE.SPOT_ADD else @MODE.SPOT_LIST

		onSaveButtonClick: =>
			if @spot.isValid(true)
				@ui.saveButton.addClass('is-loading')
				(new Iconto.REST.AddressSpot()).save(@spot.toJSON())
				.then (spot) =>
					@collection.unshift spot
					@state.set mode: @MODE.SPOT_LIST
					@spot.set description: ''
				.catch (error) =>
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
				.then =>
					@ui.saveButton.removeClass('is-loading')

		onCancelButtonClick: =>
			@state.set mode: @MODE.SPOT_LIST
			@spot.set description: ''

		onChildviewSpotDelete: (view) =>
			Iconto.shared.views.modals.Confirm.show
				title: 'Удаление точки'
				message: 'Вы уверены, что хотите удалить точку?'
				onSubmit: =>
					model = view.model
					model.destroy(wait: true)
					.then (response) =>
						@collection.remove model.get('id')
					.catch (error) =>
						console.error error
						Iconto.shared.views.modals.ErrorAlert.show error