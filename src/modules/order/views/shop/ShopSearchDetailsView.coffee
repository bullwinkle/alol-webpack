#= require ./ShopProductDetailsView

@Iconto.module 'order.views', (Views) ->

	class Views.ShopSearchDetailsView extends Views.ShopProductDetailsView
#		onHeadClick: (e) =>
#			e.preventDefault()
#			@destroy()
#			Iconto.shared.router.navigateBack()
#			return false

		updateHeadLink: =>
			@model.set
#				headHref: headLink
				headTitle: "Результаты поиска"