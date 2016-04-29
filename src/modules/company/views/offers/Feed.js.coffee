#= require ./FeedItem

@Iconto.module 'company.views.offers', (Offers) ->

	class FeedState extends	Iconto.company.models.StateViewModel
		defaults: Iconto.shared.helpers.inherit Iconto.company.models.StateViewModel::defaults,
		#state
			stateName: ''
			error: false
			empty: true
			isLoading: false
			isLoadingMore: true
			isLoadingFilters: true
			isLoadingCities: false
			isGeolocationDisabled: false
			isSearchBlockVisible: false
			_prevSubPage: ""
		# panels
			showSidebar: false
			showFilters: false
			showCities: false
		# options
			cityInputDisabled: false
			filters: []
			cities: []
			cityQueryString: ''
		#search
			lat: null
			lon: null
			queryString: ''
			publicFeed: false # is personal
			appliedFilterIds: []
			selectedCity: name: 'Автовыбор'
			cityId: 0
		#someHooks
			alreadyWasOnFeed: false


	class Offers.FeedView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView

		className: 'offers offers-feed mobile-layout'

		template: JST['company/templates/offers/feed']

		childView: Offers.FeedItemView

		childViewContainer: '.feed-list'

		behaviors:
			Epoxy: {}
			Layout: {}
#			QueryParamsBinding:
#				bindings: [
#					model: 'state'
#					fields: ['queryString', 'appliedFilterIds', 'selectedCity', 'lat', 'lon']
#				]
			InfiniteScroll:
				scrollable: '.feed-list-wrapper'
				offset: 2000

		ui:
			'viewContent': '.view-content'
			'feedList': '.feed-list'
			topbarLeftButton: '.topbar-region .left-small'
			topbarRightButton: '.topbar-region .right-small'

		events:
			'click @ui.tabFeed': 'onTabFeedClick'
			'click @ui.tabFavourites': 'onTabFavouritesClick'
			'click @ui.toggleFilters': 'onFiltersListToggleClick'
			'click @ui.filtersReset': 'onFiltersResetClick'
			'click @ui.filtersReady': 'onFiltersReadyClick'
			'click @ui.filter': 'onFilterClick'
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'

		collectionEvents:
			'add remove reset': 'onCollectionChange'

		initialize: ->
			@model = new Iconto.REST.User @options.user
			@collection = new Iconto.REST.PromoFeedCollection() # http://confluence.iconto.local/pages/viewpage.action?title=feed&spaceKey=API
			@infiniteScrollState.set
				limit: 20

			@state = new FeedState @options
			@state.set
				topbarLeftButtonClass: ''
				topbarLeftButtonSpanClass: 'ic-chevron-left'

			@_localFeedViewInitialize()

		onRender: =>
			@reload()
			(new Iconto.REST.Company(id: @state.get('companyId'))).fetch()
			.then (company) =>
				@state.set
					company: company
					topbarRightLogoUrl: _.get company, 'image.url', ''
					topbarRightLogoIcon: ICONTO_COMPANY_CATEGORY[_.get(company, 'category_id', '')] || ''
					topbarRightButtonSpanClass: 'yes'
			.catch (err) =>
				console.warn err

		onChildviewShow: (view) =>
			limit = @infiniteScrollState.get 'limit'
			deferTime = (view._index%limit)*100

			setTimeout view.$el.removeClass.bind( view.$el, 'before-show'), deferTime

		onCollectionChange: =>
			@state.set empty: @collection.length is 0

		onTopbarLeftButtonClick: =>
			defaultRoute = "/wallet/cards"
			parsedUrl = Iconto.shared.helpers.navigation.parseUri()
			fromRoute = _.get parsedUrl, 'query.from'
			route = fromRoute or defaultRoute
			Iconto.shared.router.navigate route, trigger: true

		onTopbarRightButtonClick: =>
			route = "/wallet/company/#{@state.get('companyId')}/info"
			Iconto.shared.router.navigate route, trigger: true

		reload: =>
			@state.set 'isLoadingMore', true
			@collection.reset()
			@infiniteScrollState.set
				offset: 0
				complete: false
			@preload()
			.dispatch(@)
			.catch (error) ->
				console.error error
				@state.set 'stateName', 'error'
				switch error.status
					when 200002
						console.error error.msg
					else
						Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@updateState()

		updateState: =>
			@state.set 'isLoadingMore', false

		getQuery: =>
			query = {}
			if @state.get('addressId')
				query.address_id = @state.get('addressId')
			else
				query.expand = true
				query.company_id = @options.companyId
				query.object_type = Iconto.REST.PromoFeed.OBJECT_TYPE_PROMOTION
			query.user_id = @model.get('user_id')
			query

		getBaseRoute: =>
			companyId = @state.get('companyId')
			addressId = @state.get('addressId')

			route = "/wallet/company/#{companyId}"
			route += "/address/#{addressId}" if addressId
			route += "/offers"

			route

		_localFeedViewInitialize: =>
			@state.set
				topbarTitle: 'Акции и новости'
				empty: true
				isLoadingMore: true

#			unless Iconto.shared.router.isRoot
#				@state.set
#					topbarLeftButtonClass: ''
#
#					topbarLeftButtonSpanClass: 'ic-chevron-left'

		_loadMore: =>
			PromoFeed = Iconto.REST.PromoFeed
			PromoFeedCollection = Iconto.REST.PromoFeedCollection

			Q.fcall =>
				state = @infiniteScrollState.toJSON()
				return false if state.complete

				@state.set 'isLoadingMore': true
				query =
					limit: state.limit, offset: state.offset
				_.extend query, @getQuery() #override to specify custom params
				(new PromoFeedCollection()).fetchAll(query)
				.then (feeds) =>
					@infiniteScrollState.set 'complete', true if state.limit > feeds.length
					@infiniteScrollState.set
						isLoading: false
						offset: state.offset + feeds.length #feeds.length - actual amount of loaded entities

					promotionIds = []
					cashbackIds = []
					cashbackListIds = []
					companyIds = []

					for feed in feeds

						unless feed.company_id in companyIds
							companyIds.push feed.company_id

						switch feed.object_type
							when PromoFeed.OBJECT_TYPE_PROMOTION
								unless feed.object_id in promotionIds
									promotionIds.push feed.object_id
							when PromoFeed.OBJECT_TYPE_CASHBACK
								unless feed.object_id in cashbackIds
									cashbackIds.push feed.object_id
							when PromoFeed.OBJECT_TYPE_CASHBACK_GROUP
								unless feed.object_id in cashbackListIds
									cashbackListIds.push feed.object_id

					Q.all([
						(new Iconto.REST.PromotionCollection()).fetchByIds(promotionIds),
						(new Iconto.REST.CashbackTemplateCollection()).fetchByIds(cashbackIds),
						(new Iconto.REST.CompanyCollection()).fetchByIds(companyIds),
					])
					.then ([promotions, cashbacks, companies]) =>

						for cashback in cashbacks
							if cashback.company_id isnt 0
								cashback.company = _.find companies, (company) -> company.id is cashback.company_id

						for promotion in promotions
							if promotion.company_id isnt 0
								promotion.company = _.find companies, (company) -> company.id is promotion.company_id

						for promotion in promotions
							if promotion.company_id isnt 0
								promotion.company = _.find companies, (company) -> company.id is promotion.company_id

						readyFeeds = []
						for feed in feeds
							feed.object_data = switch feed.object_type
								when  PromoFeed.OBJECT_TYPE_CASHBACK
									_.find(cashbacks, (cashback) -> cashback.id is feed.object_id)

								when PromoFeed.OBJECT_TYPE_PROMOTION
									_.find(promotions, (promotion) -> promotion.id is feed.object_id)

								when PromoFeed.OBJECT_TYPE_CASHBACK_GROUP
										{
											company: _.find companies, (company) -> company.id is feed.company_id
											cashbackCount: feed.cashback_count
											cashbackMaxPercent: feed.cashback_max_percent
										}
							if feed.object_data
								readyFeeds.push feed

						@state.set 'isLoadingMore': false

						@collection.add readyFeeds
