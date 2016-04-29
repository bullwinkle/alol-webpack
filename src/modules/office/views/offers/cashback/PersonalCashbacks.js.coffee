@Iconto.module 'office.views.offers', (Offers) ->

	class Offers.PersonalCashbackItemView extends Marionette.ItemView
		className: 'personal-cashback-item-view request-item-view'
		template: JST['office/templates/offers/cashback/personal-cashback-item']

		events:
			'click button': 'onClick'

		onClick: =>
			@trigger 'click', @model


	class Offers.PersonalCashbacksView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
		template: JST['office/templates/offers/cashback/personal-offers']
		className: 'personal-cashbacks-view mobile-layout with-bottombar'
		childView: Offers.PersonalCashbackItemView
		childViewContainer: '.list'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['templates/mobile-layout']
				outlets:
					bottombar: JST['office/templates/offers/bottombar']
			OrderedCollection: {}

		serializeData: =>
			state: @state.toJSON()

		collectionEvents:
			'add remove reset': 'onCollectionChange'

		ui:
			topbarRightButton: '.topbar-region .right-small'
			cashbacksButton: '.cashback-type-tabs .common-tab button'

		events:
			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'
			'click @ui.cashbacksButton': 'onCashbacksButtonClick'

		childViewOptions: =>
			addressCount: @state.get('addressCount')

		initialize: =>
			@state = new Iconto.office.models.StateViewModel @options
			@state.set
				topbarTitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal, leadingComma: true)}"
				topbarSubtitle: 'Предложения'
#				topbarRightButtonSpanClass: 'ic-plus-circle'

				empty: false

			@collection = new Iconto.REST.DiscountCardCollection()

		getQuery: =>
			company_id: @state.get('companyId')
			filter: 'personal'

		onRender: =>
			@preload()
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set 'isLoading', false

		onChildviewClick: (childView, itemModel) =>
			Iconto.office.router.navigate "office/#{@state.get('companyId')}/offers/request/#{itemModel.get('id')}", trigger: true

		onTopbarRightButtonClick: =>
			Iconto.office.router.navigate "office/#{@state.get('companyId')}/offers/cashback/new", trigger: true

		onCashbacksButtonClick: =>
			Iconto.office.router.navigate "office/#{@state.get('companyId')}/offers/cashbacks", trigger: true

		onCollectionChange: =>
			@state.set 'empty', !@collection.length