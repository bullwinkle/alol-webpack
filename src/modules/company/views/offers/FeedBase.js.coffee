#= require ./FeedItem

@Iconto.module 'company.views.offers', (Offers) ->

	class FeedState extends	Backbone.Model
		defaults:
			empty: true
#			isLoading: false
			isLoadingMore: true
			queryString: ''


	class Offers.FeedBaseView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView

		className: 'offers offers-feed'

		template: JST['company/templates/offers/feed-base']

		childView: Offers.FeedItemView

		childViewContainer: '.feed-list'

		behaviors:
			Epoxy: {}
			Layout:
				template: false
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

		events:
			'click @ui.tabFeed': 'onTabFeedClick'
			'click @ui.tabFavourites': 'onTabFavouritesClick'
			'click @ui.toggleFilters': 'onFiltersListToggleClick'
			'click @ui.filtersReset': 'onFiltersResetClick'
			'click @ui.filtersReady': 'onFiltersReadyClick'
			'click @ui.filter': 'onFilterClick'
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'

		collectionEvents:
			'add remove reset': 'onCollectionChange'

		bindings:
			".loader-bubbles": "toggle: state_isLoadingMore"
			".feed-list-wrapper": "toggle: not(state_isLoadingMore)"
			".no-feeds": "toggle: all( not(state_isLoadingMore), state_empty )"


		initialize: ->
			@model = new Iconto.REST.User @options.user
			@collection = new Iconto.REST.PromoFeedCollection() # http://confluence.iconto.local/pages/viewpage.action?title=feed&spaceKey=API
			@infiniteScrollState.set
				limit: 2000

			@state = new FeedState @options

			@_localFeedViewInitialize()

		onRender: =>
			@reload()

		onChildviewShow: (view) =>
			limit = @infiniteScrollState.get 'limit'
			deferTime = (view._index%limit)*100

			setTimeout view.$el.removeClass.bind( view.$el, 'before-show'), deferTime

		onChildviewElClick: (view, options) =>
			clickedModel = view.model
			companyId = clickedModel.get('company_id')

			route = if @state.get 'companyCashbacksGroup'
				"#{@getBaseRoute()}/cashbacks/#{ companyId }/#{ clickedModel.get('id') }"
			else
				switch clickedModel.get 'object_type'
					when Iconto.REST.PromoFeed.OBJECT_TYPE_PROMOTION
						"#{@getBaseRoute()}/promotion/#{ clickedModel.get('id') }"

					when Iconto.REST.PromoFeed.OBJECT_TYPE_CASHBACK
						"#{@getBaseRoute()}/cashback/#{ clickedModel.get('id') }"

					when Iconto.REST.PromoFeed.OBJECT_TYPE_CASHBACK_GROUP
						"#{@getBaseRoute()}/cashbacks/#{ companyId }"


			Iconto.wallet.router.navigate route, trigger: true

		onCollectionChange: =>
			@state.set empty: @collection.length is 0

		onTopbarLeftButtonClick: =>
			Iconto.shared.router.navigateBack()

			if @columns[0].offsetTop < @columns[1].offsetTop
				currentColumnIndex = 0
			else if @columns[0].offsetTop > @columns[1].offsetTop
				currentColumnIndex = 1
			else
				currentColumnIndex = index%@columnLength

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
				topbarTitle: 'Предложения компании'
				empty: true
				isLoading: false
				isLoadingMore: true

		_loadMore: =>
			PromoFeed = Iconto.REST.PromoFeed
			PromoFeedCollection = Iconto.REST.PromoFeedCollection

			Q.fcall =>
				state = @infiniteScrollState.toJSON()
				return false if state.complete

				@infiniteScrollState.set 'isLoadingMore', true
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
					categoryIds = []

					for feed in feeds

						unless feed.company_id in companyIds
							companyIds.push feed.company_id
						unless feed.category_id in categoryIds
							categoryIds.push feed.category_id

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
						(new Iconto.REST.CompanyCategoryCollection()).fetchByIds(categoryIds)
					])
					.then ([promotions, cashbacks, companies, categories]) =>
						for company in companies
							if company.category_id isnt 0
								company.category = _.find categories, (category) -> category.id is company.category_id

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

						@state.set 'isLoadingMore', false

						@collection.add readyFeeds
