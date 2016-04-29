@Iconto.module 'company.views', (Views) ->
	class Promotion extends Marionette.ItemView
		className: 'promotion'
		template: JST['company/templates/company/promotion']

		events:
			'click': 'onClick'

		templateHelpers: =>
			period: =>
				result = ""

				if @model.get('object_data').period_from
					periodFrom = moment.unix(@model.get('object_data').period_from)
					from = periodFrom.format('D MMMM YYYY')
					from = periodFrom.format('D MMMM') if periodFrom.year() is moment().year()
					result = "С #{from}"

				if @model.get('object_data').period_to
					periodTo = moment.unix(@model.get('object_data').period_to)
					to = periodTo.format('D MMMM YYYY')
					to = periodTo.format('D MMMM') if periodTo.year() is moment().year()
					result += " по #{to}"

				result

			time: =>
				timeFrom = @model.get('object_data').work_time[0][0][0]
				timeTo = @model.get('object_data').work_time[0][0][1]

				return 'Действует круглосуточно' if timeFrom is 0 and timeTo is 60 * 60 * 24 - 1

				tfh = Math.floor(timeFrom / 3600).toString()
				tfh = if tfh.length is 1 then "0#{tfh}" else tfh
				tfm = (timeFrom % 3600).toString()
				tfm = if tfm.length is 1 then "0#{tfm}" else tfm

				from = "#{tfh}:#{tfm}"

				tth = Math.floor(timeTo / 3600).toString()
				tth = if tth.length is 1 then "0#{tth}" else tth
				ttm = (timeTo % 3600).toString()
				ttm = if ttm.length is 1 then "0#{ttm}" else ttm

				to = "#{tth}:#{ttm}"

				"Действует ежедневно с #{from} по #{to}"

		onRender: =>
			data = @model.get('object_data')

			if data.images.length
				@$('.promotion-image').css 'background-image', "url(#{data.images[0]})"

		onClick: =>
			entityName =  switch @model.get('object_type')
				when Iconto.REST.PromoFeed.OBJECT_TYPE_PROMOTION
					'promotion'
				when Iconto.REST.PromoFeed.OBJECT_TYPE_CASHBACK
					'cashback'
				when Iconto.REST.PromoFeed.OBJECT_TYPE_CASHBACK_GROUP
					'cashbacks'
#			route = "wallet/offers/"
#			route += if @model.get('object_type') is Iconto.REST.PromoFeed.OBJECT_TYPE_PROMOTION then 'promotion/' else 'cashback/'
#			route += @model.get('id')

			route = "wallet/company/#{@options.companyId}/offers/#{entityName}/#{@model.get('id')}"

			Iconto.shared.router.navigate route, trigger: true

	class Views.CompanyOffersView extends Marionette.CompositeView
		className: 'company-promotions-view'
		template: JST['company/templates/company/promotions']
		childView: Promotion
		childViewContainer: '.promotions-list'

		behaviors:
			Epoxy: {}

		bindings:
			".promotions-content": "toggle: not(state_isLoadingPromotions)"
			".loader-bubbles": "toggle: state_isLoadingPromotions"
			".no-promotions": "toggle: not(all(state_hasPromotions, not(state_isLoadingPromotions)))"

		initialize: ->
			@model = new Iconto.REST.Company id: @options.companyId, site_url: ''
			@collection = new Iconto.REST.PromoFeedCollection()

			@state = new Iconto.company.models.StateViewModel _.extend @options,
				hasPromotions: false
				isLoadingPromotions: true

		childViewOptions: =>
			companyId: @options.companyId

		onRender: =>
			promotionsPromise = (new Iconto.REST.PromoFeedCollection()).fetchAll(company_id: @model.get('id'), limit: 100, offset: 0, expand: true)
			.then (promoFeeds) =>
				grouped = _.groupBy promoFeeds, 'object_type'

				cashbackIds = _.pluck grouped[Iconto.REST.PromoFeed.OBJECT_TYPE_CASHBACK], 'object_id'
				cashbackPromise = (new Iconto.REST.CashbackTemplateCollection()).fetchByIds(cashbackIds)

				promotionIds = _.pluck grouped[Iconto.REST.PromoFeed.OBJECT_TYPE_PROMOTION], 'object_id'
				promotionPromise = (new Iconto.REST.PromotionCollection()).fetchByIds(promotionIds)

				Promise.all([cashbackPromise, promotionPromise])
				.spread (cashbacks, promotions) =>
					_.each promoFeeds, (promoFeed) ->
						if promoFeed.object_type is Iconto.REST.PromoFeed.OBJECT_TYPE_CASHBACK
							item = _.findWhere cashbacks, id: promoFeed.object_id
							promoFeed.object_data = item if item
						if promoFeed.object_type is Iconto.REST.PromoFeed.OBJECT_TYPE_PROMOTION
							item = _.findWhere promotions, id: promoFeed.object_id
							promoFeed.object_data = item if item

					@collection.reset promoFeeds
					@state.set
						isLoadingPromotions: false
						hasPromotions: promoFeeds.length > 0
				.dispatch(@)
				.catch (error) ->
					console.log error
