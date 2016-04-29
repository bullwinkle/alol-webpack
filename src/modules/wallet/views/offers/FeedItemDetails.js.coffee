@Iconto.module 'wallet.views.offers', (Offers) ->
	class Offers.FeedItemDetailsView extends Iconto.company.views.offers.FeedItemDetailsView
		_localInitialize: =>
			entityText =  switch @state.get('objectType')
				when 'promotion'
					'анонса'
				when 'cashback'
					'шаблона CashBack'
				else 'предложения'

#			breadcrumbs = if @options.cashbackInGroup
#				[
#					{title: "Предложения", href: "/wallet/offers/feed"}
#					{title: "Группа шаблонов Cashback", href: "wallet/offers/cashbacks/#{@state.get('companyId')}"}
#					{title: "Детальная страница #{entityText}", href: "#"}
#				]
#			else
#				[
#					{title: "Предложения", href: "/wallet/offers/feed"}
#					{title: "Детальная страница #{entityText}", href: "#"}
#				]
#			@state.set 'breadcrumbs', breadcrumbs

		getRouteToBack: =>
			companyId = @state.get('companyId')
			addressId = @state.get('addressId')
			parsedUrl = Iconto.shared.helpers.navigation.parseUri()
			favourites = _.get parsedUrl, 'query.favourites'
			feed = _.get parsedUrl, 'query.feed'

			route = switch @state.get 'from' # parameter from controller
				when 'feed'
					_route = "/wallet/offers/"
					if favourites
						_route +=  'favourites'
					else
						_route +=  'feed'
					_route
				when 'feed-cashback-group'
					if feed
						"/wallet/offers/feed"
					else
						"/wallet/offers/cashbacks/#{companyId}"
				when 'company'
					_route = "/wallet/company/#{companyId}"
					_route += "/address/#{addressId}" if addressId
					_route += "/offers"
					_route
				else
					"/wallet/offers/feed"
			route