#= require ./DefaultOrder

Iconto.module 'shared.views.orders', (Orders) ->

	class OrderModel extends Backbone.Model
		defaults:
			orderViewName: 'goods'

	class Orders.OrderFormLayout extends Marionette.LayoutView
		template: JST['shared/templates/orders/layout']
		className: 'form-view-layout'

		ui:
			status: '.status'

		regions:
			orderMakerRegion: '#order-maker-region'

		orderViews:
			'default': 	Orders.DefaultOrder
			'taxi': 	Orders.TaxiFormView
			'external': Orders.ExternalFormView
			'goods': 	Orders.GoodsCategoriesView

		initialize: ->
			@model = new OrderModel @options
			@state = new Iconto.shared.models.BaseStateViewModel()
			@OrderView = @getFormView()

		getFormView: (params) =>
			queryParams = Iconto.shared.helpers.navigation.getQueryParams()
			orderViewName = queryParams.form or queryParams.page
			unless @orderViews[orderViewName]
				console.warn "Can not get view with name \"#{orderViewName}\""
				orderViewName = @model.get('orderViewName')
				return @orderViews[orderViewName]
			@model.set 'orderViewName', orderViewName
			@orderViews[orderViewName]

		showForm: (View, options={} ) =>
			@orderMakerRegion.show new View options

		onShow: =>
			@showForm @OrderView if @OrderView





