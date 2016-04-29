#= require ./DefaultOrder

Iconto.module 'order.views', (Views) ->

	class OrderModel extends Backbone.Model
		defaults:
			orderViewName: 'catalog'

	class Views.OrderFormLayout extends Marionette.LayoutView
		template: JST['order/templates/layout']
		className: 'order-layout iconto-wallet-layout mobile-layout'

		regions:
			mainRegion: '#main-region'

		initialize: ->
			@model = new OrderModel @options
			@state = new Iconto.shared.models.BaseStateViewModel()

			@OrderView = @getChildView @options

		getChildView: (params) =>
			veiwClass =  Views.factory params
			veiwClass

		showForm: (View, options={} ) =>
			if @mainRegion
				@mainRegion.show new View options
			else
				console.error 'mainRegion is not defined'

		onShow: =>
			@showForm @OrderView, state:@state if @OrderView