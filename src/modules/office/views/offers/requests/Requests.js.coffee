@Iconto.module 'office.views.offers', (Offers) ->
	class Offers.RequestItemView extends Marionette.ItemView
		className: 'request-item-view'
		template: JST['office/templates/offers/requests/request-item']

		events:
			'click button': 'onClick'

		templateHelpers: =>
			STATUS_CANCELLED: Iconto.REST.DiscountCard.STATUS_CANCELLED
			STATUS_APPROVED: Iconto.REST.DiscountCard.STATUS_APPROVED
			STATUS_PENDING: Iconto.REST.DiscountCard.STATUS_PENDING

		onClick: =>
			@trigger 'click', @model

		initialize: =>
			TYPE_WISH = 1
			TYPE_DISCOUNT_CARD = 2
			TYPE_PERSONAL_CASHBACK = 3

			data = @model.toJSON()
			type =
				if data.card_number
					TYPE_DISCOUNT_CARD
				else
					TYPE_WISH
			@model.set 'type', type

	class Offers.RequestsView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
		className: 'requests-view mobile-layout with-bottombar'
		template: JST['office/templates/offers/requests/requests']
		childView: Offers.RequestItemView
		childViewContainer: '.list'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
				outlets:
					bottombar: JST['office/templates/offers/bottombar']

		ui:
			wishesButton: '.requests-tabs .wishes-tab button'

		events:
			'click @ui.wishesButton': 'onWishesButtonClick'

		serializeData: =>
			state: @state.toJSON()

		initialize: =>
			@state = new Iconto.office.models.StateViewModel @options
			@state.set
				topbarTitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal, leadingComma: true)}"
				topbarSubtitle: 'Предложения'

			@collection = new Iconto.REST.DiscountCardCollection()

		getQuery: =>
			company_id: @state.get('companyId')
			filter: 'card'

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

		onWishesButtonClick: =>
			Iconto.office.router.navigate "office/#{@state.get('companyId')}/offers/requests/wishes", trigger: true

