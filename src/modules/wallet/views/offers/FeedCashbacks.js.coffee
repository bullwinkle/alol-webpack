#= require ./FeedItem

@Iconto.module 'wallet.views.offers', (Offers) ->

	inherit = Iconto.shared.helpers.inherit

	isEqualArrays = (first, second) ->
		if first.length isnt second.length
			return false
		for el, i in first
			if first[i] isnt second[i]
				return false
		true

	class SavedStateProperties extends Backbone.Model
		defaults:
			appliedFilterIds: []
			personalFeed: true
			selectedCity: {}
			queryString: ''

	class Offers.FeedCashbacksView extends Iconto.company.views.offers.FeedView
		className: 'offers offers-feed cashback-group mobile-layout'
		template: JST['wallet/templates/offers/feed']

		childView : Offers.FeedItemView

		childViewContainer : '.feed-list'

		behaviors: inherit Iconto.company.views.offers.FeedView::behaviors,
			QueryParamsBinding:
				bindings: [
					model: 'state'
					fields: ['queryString', 'appliedFilterIds', 'selectedCity', 'lat', 'lon']
				]

		ui:
			topbar: '.topbar-region'
			'viewContent': '.view-content'
			'queryString': 'input.search'
			'showAllFeedsButton':'.show-all-feeds'

			'sidebar': '.sidebar-right'
			'showSidebarButton': '.search .serch-filters:not([disabled])'
			'hideSidebarButton': '.hide-sidebar:not([disabled])'

			'filters': '.filters'
			'showFiltersButton': '.show-filters:not([disabled])'
			'hideFiltersButton': '.filters-ready:not([disabled])'
			'resetFiltersButton': '.filters-reset:not([disabled])'

			'cities': '.cities'
			'cityInput': '.city-input'
			'showCitiesButton': '.show-cities:not([disabled])'
			'hideCitiesButton': '.cities-ready:not([disabled])'
			'resetCitiesButton': '.cities-reset:not([disabled])'
			'cityItem': '.city-item'

			'filtersContent': '.filters-content'
			'filter': 'li.filter'
			'feedListWrapper': '.list-wrapper'
			'feedList': '.feed-list'

#			'enablePersonalFeedButton': '.is-personal .enable:not([disabled])'
#			'disablePersonalFeedButton': '.is-personal .disable:not([disabled])'

		events:
			'click @ui.showAllFeedsButton': 'onShowAllClick'

			'click @ui.showSidebarButton': 'onShowSidebarClick'
			'click @ui.hideSidebarButton': 'onHideSidebarClick'

			'click @ui.showFiltersButton' : 'onShowFiltersClick'
			'click @ui.hideFiltersButton' : 'onHideFiltersClick'
			'click @ui.resetFiltersButton': 'onResetFiltersClick'
			'click @ui.filter' : 'onFilterClick'

			'click @ui.showCitiesButton': 'onShowCitiesClick'
			'click @ui.hideCitiesButton': 'onHideCitiesClick'
			'click @ui.resetCitiesButton' : 'onResetCitiesClick'
			'click @ui.cityItem' : 'onCityItemClick'

			'mousedown @ui.sidebar': 'onSidebarMouseDown'

#			'click @ui.enablePersonalFeedButton': 'onEnablePersonalFeedClick'
#			'click @ui.disablePersonalFeedButton': 'onDisablePersonalFeedClick'

			'click .disabled' : 'onDisabledControllClick'

		collectionEvents:
			'add remove reset': 'onCollectionChange'

		initialize: =>
			super()
			@state.set
				topbarTitle: 'Группа шаблонов Cashback'
				tabs: []
				breadcrumbs: [
					title: "Предложения", href: "/wallet/offers/feed"
				,
					title: "Группа шаблонов Cashback", href: "#"
				]
				isSearchBlockVisible: false

		childViewOptions: =>
			cashbackInGroup: true

		onRender: =>
			@reload()

		onChildviewElClick: (view, options) =>
			clickedModel = view.model
			companyId = clickedModel.get('company_id')

			route = "/wallet/offers/cashbacks/#{companyId}/#{ clickedModel.get('id') }"

			Iconto.wallet.router.navigate route, trigger: true

		getQuery: =>
			query =
				user_id: @model.get 'user_id'
				object_type: Iconto.REST.PromoFeed.OBJECT_TYPE_CASHBACK
				company_id: @state.get 'companyId'

			query