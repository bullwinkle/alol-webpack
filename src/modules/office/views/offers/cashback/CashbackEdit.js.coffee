@Iconto.module 'office.views.offers', (Offers) ->

	inherit = Iconto.shared.helpers.inherit
	
	class CompanyTreatyAlert extends Iconto.shared.views.modals.Alert
		template: JST['office/templates/offers/cashback/company-treaty-alert']

	class Offers.CashbackEditView extends Offers.BaseOfferEditView

		ModelClass: Iconto.REST.CashbackTemplate
		
		template: JST['office/templates/offers/cashback/cashback-edit']
		className: 'cashback-edit-view mobile-layout'

		regions: inherit Offers.BaseOfferEditView::regions
		
		behaviors: inherit Offers.BaseOfferEditView::behaviors

		ui: inherit Offers.BaseOfferEditView::ui,
			birthdayBeforeInput: '#birthday-before'
			birthdayAfterInput: '#birthday-after'
			loadBinInfo: '.load-bank-info'
			banks: '.banks'

		events: inherit Offers.BaseOfferEditView::events,
			'click .banks .bank .remove-bank': 'onBankRemoveClick'
			'click @ui.loadBinInfo': 'onLoadBinInfoClick'

		modelEvents: inherit Offers.BaseOfferEditView::modelEvents,
			'change:at_birthday': '_updateModelBirthday'
			'change:birthday_before': '_updateModelBirthdayBefore'
			'change:birthday_after': '_updateModelBirthdayAfter'

		initialize: ->
			super()
			@commonModel.set
				entityName: 'Шаблон Cashback'
				successSavedRoute: "office/#{@state.get('companyId')}/offers/cashbacks"
				objectType: Iconto.REST.PromoFeed.OBJECT_TYPE_CASHBACK

			@model = new @ModelClass
				id: @options.cashbackId
				company_id: @options.companyId
				
			modelIsNew = @model.isNew()
			pageTitle = "#{if modelIsNew then 'Создание нового' else 'Редактирование'} шаблона Cashback"
			@state.set
				topbarTitle: pageTitle
				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal, leadingComma: true)}"
				breadcrumbs: [
					{
						title: 'Предложения',
						href: "/office/#{@options.companyId}/offers/cashbacks"
					},
					{
						title: pageTitle,
						href: "/office/#{@options.companyId}/offers/cashback/#{if modelIsNew then 'new' else @model.get('id')}"
					}
				]

				bankBin: null
				banks: []
				gotSelectedDays: true


		onRender: =>
			super()
			promise = Q.fcall =>
				unless @model.isNew()
					@model.fetch({}, {validate: false})
					.then (objectData) =>
						@oldModelOnRender objectData
				else
					@newModelOnRender()
					true
			promise
			.then =>
				@bindModelChangeWorkTimeEvents()

				if @model.get('bank_id')
					(new Iconto.REST.Bank(id:@model.get('bank_id'))).fetch()
					.then (bank) =>
						banks = []
						banks.push bank
						@state.set 'banks', banks
					.catch (error) =>
						console.error error
						Iconto.shared.views.modals.ErrorAlert.show error
					.done()

			.catch (error) =>
				console.error error
				@handleModelError error
			.done =>
				@modelFetchingDone()

				@checkWeekDays()
				@listenTo @state,
					'change:monday': @checkWeekDays
					'change:tuesday': @checkWeekDays
					'change:wednesday': @checkWeekDays
					'change:thursday': @checkWeekDays
					'change:friday': @checkWeekDays
					'change:saturday': @checkWeekDays
					'change:sunday': @checkWeekDays

			@loadAddresses()

		_updateModelBirthday: =>
			if @model.get('at_birthday')
				@state.set
					'birthday_before': @model.get 'birthday_before'
					'birthday_after': @model.get 'birthday_after'
				@model.set {
					"birthday_before": '0'
					"birthday_after": '0'
				}, {validate: @setterOptions.validate }

				@ui.birthdayBeforeInput.prop 'disabled', true
				@ui.birthdayAfterInput.prop 'disabled', true
			else
				@model.set {
					"birthday_before": @state.get 'birthday_before'
					"birthday_after": @state.get 'birthday_after'
				}, {validate: @setterOptions.validate }

				@ui.birthdayBeforeInput.prop 'disabled', false
				@ui.birthdayAfterInput.prop 'disabled', false

		_updateModelBirthdayBefore: =>
			if @model.get('birthday_before')?.length is 0
				@model.set 'birthday_before', null

		_updateModelBirthdayAfter: =>
			if @model.get('birthday_after')?.length is 0
				@model.set 'birthday_after', null

		onBankRemoveClick: (e) =>
			@model.set('bank_id', 0)
			@state.set('banks',[])

		onLoadBinInfoClick: =>
			bin = @state.get('bankBin')+''
			unless bin.length is 6
				return Iconto.shared.views.modals.Alert.show
					message: "В БИН-номере банка должно быть 6 цифр."
			(new Iconto.REST.Bank()).fetch({query: @state.get('bankBin')},{ reload: true})
			.then (bank) =>
				errorMessage = 'Банк не найден'
				bankId = bank?.items?[0]?.id
				throw message: errorMessage unless bankId
				(new Iconto.REST.Bank(id:bankId)).fetch(reload: true)
				.then (bank) =>
					throw message: errorMessage unless bank.id
					@model.set 'bank_id', bank.id
					banks = []
					banks.push bank
					@state.set 'banks', banks
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onFormSubmit: =>
			return false unless @checkForTreaty @state.get('company')
			@checkWeekDays()
			super()

		checkWeekDays: =>
			isActive =  _ ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
			.map (dayName) => return @state.get dayName
			.some()

			@state.set 'gotSelectedDays', isActive
			unless isActive
				@model.set 'is_active', isActive
