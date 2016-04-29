@Iconto.module 'wallet.views.offers', (Offers) ->
	class Offers.FeedItemView extends Iconto.company.views.offers.FeedItemView

		_localInitialize: =>
			@state.set isHideButtonShown: true
			@events['click .hide-feed-item'] = 'onHideFeedItemClick'
			@events['click .reestablish-feed-item'] = 'onReestablishClick'

		onHideFeedItemClick: =>
			@ui.el.addClass 'is-hidden'
			@trigger 'hideButtonClicked'

		onReestablishClick: =>
			@ui.el.removeClass 'is-hidden'
			@trigger 'hideButtonClicked'

		generateDetailsHref:  =>
			companyId = @model.get('company_id')

			cashbackGroup = @options.cashbackInGroup
			favourites = @options.favourites

			href = switch @model.get 'object_type'
				when Iconto.REST.PromoFeed.OBJECT_TYPE_PROMOTION
					_href = "/wallet/offers/promotion/#{ @model.get('id') }"
					if favourites
						_href += '?favourites=true'
					_href

				when Iconto.REST.PromoFeed.OBJECT_TYPE_CASHBACK
					_href = "/wallet/offers/"
					if @options.cashbackInGroup
						_href += "cashbacks/#{companyId}/"
					else
						_href += "cashback/"
					_href += "#{ @model.get('id') }"
					if favourites
						_href += '?favourites=true'
					_href

				# feeds do not grouping in company
				when Iconto.REST.PromoFeed.OBJECT_TYPE_CASHBACK_GROUP
					"/wallet/offers/cashbacks/#{companyId}"
			href