@Iconto.module 'office.views.shop', (Shop) ->
	class EmptyView extends Marionette.ItemView
		template: JST['office/templates/shop/orders/empty']

	class OrderView extends Marionette.ItemView
		className: 'order'
		template: JST['office/templates/shop/orders/order']

		behaviors:
			Epoxy: {}

		computeds:
			hideNickname: ->
				!@getBinding('nickname')

		events:
			'click .order-wrapper': 'onExpandClick'
			'click [name=approve]': 'onApproveButtonClick'
			'click [name=cancel]': 'onCancelButtonClick'

		initialize: =>
			count = _.reduce @model.get('shop_goods'), (memo, num) ->
				memo + num.count
			, 0
			phone = @model.get('phone')
			phone = "+7 #{Iconto.shared.helpers.phone.format7(phone)}" if phone
			@model.set
				goods_count: count
				statusClass: 'yellow inline filled'
				statusText: 'Ожидает'
				goods: []
				nickname: ''
				phone: phone

			@listenTo @model, 'change:status', @onStatusChange

			@onStatusChange()

		onStatusChange: =>
			statusClass = 'yellow'
			statusText = ''
			switch @model.get('status')
				when Iconto.REST.ShopOrder.ORDER_STATUS_PENDING
					statusClass = 'yellow inline filled'
					statusText = 'Ожидает'
				when Iconto.REST.ShopOrder.ORDER_STATUS_CANCEL
					statusClass = 'red inline filled'
					statusText = 'Отклонен'
				when Iconto.REST.ShopOrder.ORDER_STATUS_APPROVE
					statusClass = 'green inline filled'
					statusText = 'Выполнен'
				else
					statusClass = 'yellow inline filled'
					statusText = 'Ожидает'

			@model.set
				statusClass: statusClass
				statusText: statusText

		getGoods: (ids) ->
			(new Iconto.REST.ShopGoodCollection()).fetchByIds(ids)

		getCustomer: (userId, companyId) ->
			params =
				user_id: userId
				company_id: companyId
			(new Iconto.REST.CompanyClient()).fetch(params)
			.catch (error) =>
				console.log 'ERROR', error
				undefined

		getUser: (userId) ->
			(new Iconto.REST.User(id: userId)).fetch()

		onExpandClick: =>
			@$el.toggleClass('open')

			if @$el.hasClass('open') and !@model.get('goods').length

				@getGoods( _.pluck @model.get('shop_goods'), 'shop_good_id' )
				.then (goods) =>

					_.map goods, (g) =>
						fromModel = _.find @model.get('shop_goods'), (shopGood) =>
							+g.id is +shopGood.shop_good_id
						g.count = _.get fromModel, 'count'
						g

					@model.set goods: goods
				.dispatch(@)
				.catch (error) =>
					console.log 'ERROR', error
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()

				customerPromise = @getCustomer( @model.get('user_id'), @model.get('company_id') )
				userPromise = @getUser( @model.get('user_id') )

				Promise.all([customerPromise, userPromise])
				.spread (customer, user) =>
					if customer
						nickname = ("#{customer.first_name_display or ''} #{customer.last_name_display or ''}").trim()
						nickname = user.nickname unless nickname
						@model.set nickname: nickname
				.dispatch(@)
				.catch (error) =>
					console.log 'ERROR', error
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()

		onApproveButtonClick: (e) =>
			e.stopPropagation()
			@model.save(status: Iconto.REST.ShopOrder.ORDER_STATUS_APPROVE)
			.then =>
				console.log 'done'
			.dispatch(@)
			.catch (error) =>
				console.log 'ERROR', error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onCancelButtonClick: (e) =>
			e.stopPropagation()
			@model.save(status: Iconto.REST.ShopOrder.ORDER_STATUS_CANCEL)
			.then =>
				console.log 'cancel'
			.dispatch(@)
			.catch (error) =>
				console.log 'ERROR', error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()


	class Shop.OrdersView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
		className: 'shop-orders-view mobile-layout'
		template: JST['office/templates/shop/orders/orders']
		childView: OrderView
		childViewContainer: '.list'
		emptyView: EmptyView

		behaviors:
			Epoxy: {}
			Layout: {}
			InfiniteScroll:
				scrollable: '.view-content'

		ui:
			topbarRightButton: '.topbar-region .right-small'

		events:
			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'

		getQuery: => #used for specifying additional params while fetching
			result =
				company_id: @state.get('companyId')
			query = @state.get('query')
			result.query = query if query
			result

		initialize: =>
			@collection = new Iconto.REST.ShopOrderCollection()

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: ''
				topbarSubtitle: ''
#				topbarRightButtonSpanClass: 'ic-settings'
				isLoading: true
				tabs: [
					{title: 'Товары', href: "office/#{@options.companyId}/shop"}
					{title: 'Заказы', href: "office/#{@options.companyId}/shop/orders", active: true}
					{title: 'Настройки', href: "office/#{@options.companyId}/shop/orders/edit"}
					{title: 'Добавить транзакцию', href: "/office/#{@options.companyId}/add-transaction"}
				]

		onRender: =>
			@preload() #defined in BaseInfiniteCompositeView
			.then =>
				@state.set isLoading: false
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

#			@collection.fetch(company_id: @options.companyId)
#			.then =>
#				@state.set isLoading: false
#			.dispatch(@)
#			.catch (error) =>
#				console.log 'ERROR', error
#			.done()

		onTopbarRightButtonClick: =>
			Iconto.office.router.navigate "/office/#{@options.companyId}/shop/orders/edit", trigger: true