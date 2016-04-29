@Iconto.module 'office.views.offers', (Offers) ->

	inherit = Iconto.shared.helpers.inherit

	class Offers.BaseOffersView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
#		className: 'cashbacks-view mobile-layout with-bottombar'
		childViewContainer: '.list'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
			InfiniteScroll:
				scrollable: '.list-wrapper'
				offset: 2000

		serializeData: =>
			state: @state.toJSON()

		ui:
			topbarRightButton: '.topbar-region .right-small'
			cashbackTemplateCount: '.cashback-template-count'
			personalCashbacksButton: '.cashback-type-tabs .personal-tab button'
			tabCashback: '.tabs .cashback'
			tabPromotion: '.tabs .promotion'

		collectionEvents:
			'add reset remove': 'onCollectionChange'

		events:
			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'
			'click @ui.personalCashbacksButton': 'onPersonalCashbacksButtonClick'
			'click @ui.tabPromotion': 'onTabPromotionClick'

		initialize: =>
			@state = new Iconto.office.models.StateViewModel @options
			@state.set
				topbarRightButtonSpanClass: 'ic-plus-circle'
				isLoading: false
				isLoadingMore: true
				empty: false
				amount: 0
				isCashbackTab: false

				notification: false
				tabs: [
					{
						title: 'CashBack'
						href: "/office/#{@options.companyId}/offers/cashbacks"
						active: @options.subpage is "cashbacks"
					}, {
						title: 'Акции и предложения'
						href: "/office/#{@options.companyId}/offers/promotions"
						active: @options.subpage is "promotions"
					}
				]


			@infiniteScrollState.set
				limit: 20

		onRender: =>
			(new Iconto.REST.AddressCollection()).fetchAll(company_id: @options.companyId)
			.dispatch(@)
			.then (addresses=[]) =>
				length = if addresses?.length then addresses.length else 0
				@state.set 'addressCount': addresses.length
				@reload()

			.catch (error) =>
				console.error 'error while fetching offers', error
			.done()

		getQuery: =>
			query =
				company_id: @options.companyId
			query

		reload: =>
			@state.set 'isLoadingMore', true
			@collection.reset()
			@infiniteScrollState.set
				offset: 0
				complete: false
			@preload()
			.then => @reorder()
			.dispatch(@)
			.catch (error) ->
				console.error error
				unless error.name is 'ViewDestroyedError'
					Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set 'isLoadingMore', false

		onCollectionChange: =>
			@state.set
				amount: @collection.length
				empty: !@collection.length

		onChildviewClick: (childView, itemModel) =>
			Iconto.office.router.navigate "office/#{@state.get('companyId')}/offers/#{@entityName}/#{itemModel.get('id')}", trigger: true

		onTopbarRightButtonClick: =>
			Iconto.office.router.navigate "office/#{@state.get('companyId')}/offers/#{@entityName}/new", trigger: true

		onPersonalCashbacksButtonClick: =>
			Iconto.office.router.navigate "office/#{@state.get('companyId')}/offers/#{@entityName}s/personal", trigger: true

		childViewOptions: =>
			addressCount: @state.get('addressCount')

		onTabPromotionClick: =>
			@state.set
				isCashbackTab: false
				isLoadingMore: true
			Iconto.office.companyRouter.navigate "office/#{ @state.get('companyId') }/offers/promotions", trigger: true

		onTabCashbackClick: =>
			@state.set
				isCashbackTab: true
				isLoadingMore: true
			Iconto.office.companyRouter.navigate "office/#{ @state.get('companyId') }/offers/cashbacks", trigger: true