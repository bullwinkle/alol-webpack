#= require ./FeedItem

@Iconto.module 'wallet.views.offers', (Offers) ->

	inherit = Iconto.shared.helpers.inherit

	isEqualArrays = (first=[], second=[]) ->
		if first.length isnt second.length
			return false
		for el, i in first
			if first[i] isnt second[i]
				return false
		true

	class Offers.FeedView extends Iconto.company.views.offers.FeedView
		className: 'offers offers-feed mobile-layout'
		template: JST['wallet/templates/offers/feed']

		childView : Offers.FeedItemView

		childViewContainer : '.feed-list'

		behaviors: inherit Iconto.company.views.offers.FeedView::behaviors,
			QueryParamsBinding:
				bindings: [
					model: 'state'
					fields: [
						'queryString',
						'cityId',
						'appliedFilterIds',
						'lat',
						'lon',
						'publicFeed'
					]
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
			'clearSearchButton': '.clear-search'

			'getGeoLocation' : '.get-geolocation'

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

			'click .disabled' : 'onDisabledControllClick'
			'click @ui.clearSearchButton': 'onClearSearchButtonClick'

			'click @ui.getGeoLocation' : 'getPosition'

		collectionEvents:
			'add remove reset': 'onCollectionChange'

		_localFeedViewInitialize: =>
			@filtersCollection = new Iconto.REST.CompanyCategoryCollection()
			_.extend @filtersCollection.model::.defaults, applied: false
			@stateBuffer = new @state.constructor()
			@listenTo @state, 'change:subpage', @onStateSubpageChange
			@listenTo @state, 'change:queryString', _.debounce @onStateQueryStringChange, 300
			@listenTo @state, 'change:cityQueryString', _.debounce @onStateCityQueryStringChange, 300
			@listenTo @filtersCollection, 'change:applied', @onFiltersAppliedChange
			@listenTo @state, 'change:cityId', @onStateSelectedCityChange
			@listenTo @state, 'change:publicFeed', @onPublickFeedChange
			@listenTo @state, 'change:appliedFilterIds', @onStateAppliedFilterIdsChange

			@stateBuffer.set '_prevSubPage', @options.subpage

			@listenTo @state, 'change', (model, opts) =>
				if @state.get('subpage') is 'feed'
					@stateBuffer.set model.changed

			@updateStateBySubpage @options.subpage

		childViewOptions: =>
			switch @state.get 'subpage'
				when "favourites"
					favourites:true

		onChildviewShow: (view) =>
			limit = @infiniteScrollState.get 'limit'
			deferTime = (view._index%limit)*100

			setTimeout view.$el.removeClass.bind( view.$el, 'before-show'), deferTime

		onStateSubpageChange: (model, subpage, options) =>
			prevSubPage = @stateBuffer.get '_prevSubPage'
			@state.set isLoadingMore: true

			@updateStateBySubpage subpage, prevSubPage
			@stateBuffer.set '_prevSubPage', subpage

			@reload()

		onRender: =>
			$('#workspace').on 'mousedown.workspace', =>
				if @state.get('showSidebar')
					@onHideSidebarClick()
				return

			if @state.get 'subpage' is 'company-cashbacks'
				@$el.addClass 'cashback-group'
			else
				@$el.removeClass 'cashback-group'

			@loadFilters()
			parsedUrl = Iconto.shared.helpers.navigation.parseUri()
			queryLat =  _.get(parsedUrl, 'query.lat')
			queryLon =  _.get(parsedUrl, 'query.lon')
			publicFeed =  _.get(parsedUrl, 'query.publicFeed', false)
			if publicFeed is 'true'
				publicFeed = true
			else if publicFeed is 'false'
				publicFeed = false

			publicFeed = +!!+publicFeed

			@state.set
				publicFeed: publicFeed

			if queryLat and queryLon
				@state.set
					lat: queryLat
					lon: queryLon
				@reload()
			else
				@getPosition()
				.then =>
					@reload()

		onShow: =>
#			window.state = @state
			cityId = Iconto.shared.helpers.navigation.getQueryParams().cityId
			if cityId
				@state.set 'isLoadingCities': true
				(new Iconto.REST.City(id:cityId)).fetch()
				.then (city) =>
					@state.set
						selectedCity: city
				.catch (error) =>
					console.error error
				.done =>
					@state.set 'isLoadingCities': false

		onStateQueryStringChange: (state, value, params) =>
			@reload()

		onBeforeDestroy: =>
			$('#workspace').off 'mousedown.workspace'

		#		ITEMVIEW
		onChildviewHideButtonClicked: (childView) =>
			_.result childView, 'model.destroy'

		onSidebarMouseDown: (e) =>
			e.stopPropagation()

		#		FILTERS PANEL
		onFiltersAppliedChange: =>
			appliedFilters = @filtersCollection.filter (filterModel) -> filterModel.get 'applied'
			appliedFilterIds = _.pluck appliedFilters, 'id'
			appliedFilterIds = _.map appliedFilterIds, (filterId) -> +filterId
			@state.set 'appliedFilterIds', appliedFilterIds

		onStateAppliedFilterIdsChange: (state, appliedFilterIds, options) =>

		#		CITIES PANEL
		onShowCitiesClick: =>
			@state.set
				showCities: true

		onHideCitiesClick: =>
			@state.set
				showCities:	false

		onStateCityQueryStringChange: (model, queryValue, options) =>
			@state.set 'cities': []

			if queryValue.length < 3
				return

			@state.set 'isLoadingCities': true
			query =
				country_id: 6 # ID of Russia, by Denis Sabitov
				query: queryValue

			options =
				reload:true

			(new Iconto.REST.City()).fetch(query, options)
			.then (response) =>
				ids = response.items
				return if ids.length < 1
				(new Iconto.REST.CityCollection()).fetchByIds(ids)
				.then (cities) =>
					@state.set
						cities: cities
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set 'isLoadingCities': false

		onStateSelectedCityChange: (state, value) =>

		onPublickFeedChange: (state, value) =>
			if value is 'true'
				value = 1
			else if value is 'false'
				value = 0
			value  = +!!+value
			@state.set 'publicFeed', value, silent: true

		onShowAllClick: =>
			reloaded = @state.get('queryString').length > 0

			resetValues =
				stateName: ''
			# showing panels
				showSidebar: false
				showFilters: false
				showCities: false
			# settings panel
				appliedFilterIds: []
				publicFeed: 1
				selectedCity: {}
				queryString: ''

			resetValuesSilent = {}

			@onResetFiltersClick()
			@state.set resetValues

			unless reloaded
				@reload()

		onClearSearchButtonClick: =>
			@state.set 'queryString', ''

		onResetCitiesClick: =>
			@state.set
				selectedCity: {}
				cities: []
				cityId: 0
				cityQueryString: ''

		onCityItemClick: (e) =>
			$city = $(e.currentTarget)
			cityData = $city.data()
			citiesList = @state.get 'cities'
			selectedCityData = _.find citiesList, (city) -> city.id is cityData.cityId
			if selectedCityData

				@state.set
					selectedCity: selectedCityData
					cityId: selectedCityData.id

				@ui.cityInput.val selectedCityData.name

		onShowFiltersClick: =>
			@ui.feedListWrapper.removeAttr('data-scroll')
			@ui.filtersContent.attr('data-scroll',true)

			@state.set
				showFilters: true

		onHideFiltersClick: =>
			@ui.feedListWrapper.attr('data-scroll',true)
			@ui.filtersContent.removeAttr('data-scroll')

			@state.set
				showFilters: false

		onResetFiltersClick: =>
			@filtersCollection.each (filterModel) ->
				filterModel.set 'applied', false
			@ui.sidebar.find('.filter').removeClass 'is-applied'

			@state.set 'appliedFilterIds', []

		onFilterClick: (e) =>
			$filterEl = $(e.currentTarget)
			filterId = $filterEl.data 'filter-id'
			filterModel = @filtersCollection.get(filterId)
			filterModel.set 'applied', not filterModel.get('applied')
			if filterModel.get('applied')
				$filterEl.addClass 'is-applied'
			else
				$filterEl.removeClass 'is-applied'
			@filtersCollection.trigger 'change:applied'

		onShowSidebarClick: =>
			@state.set
				showSidebar: true

		onHideSidebarClick: =>
			@state.set
				showSidebar: false
				isLoadingMore: true

			unless Iconto.shared.helpers.transitionEndEventName
				@onHideCitiesClick()
				@onHideFiltersClick()

			transitionEndName = "#{Iconto.shared.helpers.transitionEndEventName}.hiding"
			@ui.sidebar.on transitionEndName, =>
				@ui.sidebar.off transitionEndName
				@onHideCitiesClick()
				@onHideFiltersClick()

			setTimeout @reload, 300 # TODO define, if settings was really changed


		loadFilters: =>
			@state.set 'isLoadingFilters', true
			(new Iconto.REST.CompanyCategoryCollection()).fetchAll()
			.then (filters) =>
				filterCatergories = []
				categorisedFilters = []
				appliedFilterIds = @state.get('appliedFilterIds')
				_.each filters, (filter) =>
					unless filter.parent_id
						filterCatergories.push filter
					else
						if appliedFilterIds.indexOf( +filter.id ) isnt -1
							filter.applied = true
						else
							filter.applied = false

						unless filter.icon_url
							filter.icon_url = '//static.iconto.net/images/noimage.png'
						categorisedFilters.push filter

				categorisedFilters = _.groupBy categorisedFilters, 'parent_id'
				formattedFilters = []
				for category in filterCatergories
					category.items = categorisedFilters[category.id+'']
					formattedFilters.push category

				@filtersCollection.reset filters

				@state.set 'filters', formattedFilters

			.dispatch(@)
			.catch (error) ->
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set 'isLoadingFilters', false

		updateStateBySubpage: (subpage, prevSubPage=null) =>
			if prevSubPage is 'feed'
				@stateBuffer.set 'alreadyWasOnFeed', true
			tabs = [
				title: 'Лента'
				href: '/wallet/offers/feed'
				active: subpage is 'feed'
			,
				title: 'Избранное'
				href: '/wallet/offers/favourites'
				active: subpage is 'favourites'
			]

			breadcrumbs = [
				title: "Предложения", href: "/wallet/offers/feed"
			,
				title: "Группа шаблонов Cashback", href: "#"
			]

			objToSet = {}
			switch subpage
				when  'feed'

					if @stateBuffer.get('alreadyWasOnFeed')
						objToSet = @stateBuffer.toJSON()
						delete objToSet.page
						delete objToSet.subpage
						delete objToSet._prevSubPage
					else
						objToSet =
							breadcrumbs: []
							tabs: tabs
							isSearchBlockVisible: true

				when  'favourites'
					objToSet =
						breadcrumbs: []
						tabs: tabs
						isSearchBlockVisible: true

				when  'company-cashbacks'
					objToSet =
						tabs: []
						breadcrumbs: breadcrumbs
						isSearchBlockVisible: false
			@state.set objToSet

		getQuery: =>
			query =
				user_id: @model.get 'user_id'
				filters: []

			switch  @state.get 'subpage'
				when  'feed'
					lat = @state.get('lat')
					lon = @state.get('lon')
					appliedFilterIds = @state.get 'appliedFilterIds'
					queryString = @state.get 'queryString'
					isPublicFeed = !!+@state.get('publicFeed')
					selectedCityId = @state.get('cityId')
					filters = []

					if lat and lon
						query.lat = lat
						query.lon = lon

					if appliedFilterIds?.length > 0
						query.category_ids = appliedFilterIds

					if queryString?.length > 0
						query.query = queryString

					if selectedCityId and isPublicFeed
						query.city_id = selectedCityId

					if isPublicFeed
						query.filters.push 'all'

#					if	filters.length > 0 # should be the last
#						query.filters = filters

				when  'favourites'
					query.is_favourite =  true

				when  'company-cashbacks'
					query.object_type = Iconto.REST.PromoFeed.OBJECT_TYPE_CASHBACK
					query.company_id = @state.get 'companyId'

			query

		getBaseRoute: =>
			companyId =  @state.get('companyId')
			addressId =  @state.get('addressId')
			"/wallet/offers"

		computeStateName: =>
			state = @state.toJSON()
			stateName = ''

			unless (state.empty and !state.isLoadingMore)
				return stateName = 'success'

			if state.empty and !state.isLoadingMore

				# В избранном нет предложений
				unless state.subpage is 'feed'
					return stateName = 'no_favourite_feeds'

					# В ленте избранном нет предложений
				else

					# Если нет никаких предложений
					if state.publicFeed and !(state.cityId or state.appliedFilterIds.length>0 or state.queryString)
						return stateName = 'no_feeds'

					# Если нет персональных предложений
					if !state.publicFeed and !(state.cityId or state.appliedFilterIds.length>0  or state.queryString)
						return stateName = 'no_personal_feeds'


					# Если в фильтре выбран город и/или категория, где нет предложений
					if (state.cityId or state.appliedFilterIds.length>0 or state.queryString)
						return stateName = 'no_feeds_with_conditions'
			stateName

		updateState: =>
			@state.set 'isLoadingMore', false
			stateName = @computeStateName()
			@state.set 'stateName', stateName

		getPosition: =>
			geo = Iconto.shared.services.geo
			geo.getCurrentPosition
				enableHighAccuracy: true
				maximumAge: 3 * 60 * 1000 #3 minutes
			.then (geoposition) =>
				@state.set
					lat: geoposition.coords.latitude
					lon: geoposition.coords.longitude
					isGeolocationDisabled: false

			.catch (error) =>
				console.error error
				@state.set 'isGeolocationDisabled', true