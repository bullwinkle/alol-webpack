@Iconto.module 'office.views.offers', (Offers) ->

	class Offers.WishRequestsView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
		className: 'requests-view wish-requests-view mobile-layout with-bottombar'
		template: JST['office/templates/offers/requests/requests']
		childView: Offers.RequestItemView
		childViewContainer: '.list'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
				outlets:
					bottombar: JST['office/templates/offers/bottombar']
			OrderedCollection: {}

		serializeData: =>
			state: @state.toJSON()

		ui:
			discountCardsButton: '.requests-tabs .discount-cards-tab button'

		events:
			'click @ui.discountCardsButton': 'onDiscountCardsButtonClick'

		getQuery: =>
			company_id: @state.get('companyId')
			filter: 'want'

		initialize: =>
			@state = new Iconto.office.models.StateViewModel @options
			@state.set
				topbarTitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal, leadingComma: true)}"
				topbarSubtitle: 'Предложения'

			@collection = new Iconto.REST.DiscountCardCollection()

		onRender: =>
			@preload()
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set
					isLoading: false

		onChildviewClick: (childView, itemModel) =>
			Iconto.office.router.navigate "office/#{@state.get('companyId')}/offers/request/#{itemModel.get('id')}", trigger: true

		onDiscountCardsButtonClick: =>
			Iconto.office.router.navigate "office/#{@state.get('companyId')}/offers/requests", trigger: true



