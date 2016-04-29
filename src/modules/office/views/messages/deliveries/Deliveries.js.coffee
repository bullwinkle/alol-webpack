@Iconto.module 'office.views.messages', (Messages) ->

	class Messages.DeliveryItemView extends Marionette.ItemView
		tagName: 'a'
		className: 'delivery-item-view button list-item flexbox'
		template: JST['office/templates/messages/deliveries/delivery-item']

		initialize: =>
			@$el.attr 'href', "/office/#{@model.get('company_id')}/messages/delivery/#{@model.get('id')}"

		templateHelpers: ->
			statusText: @model.getStatusText()
			statusColor: @model.getStatusColor()
			statusIcon: @model.getStatusIcon()

		events:
			'click': ->
				@trigger 'click', @model

	class Messages.DeliveriesView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
		className: 'deliveries-view mobile-layout with-bottombar'

		childView: Messages.DeliveryItemView
		childViewContainer: '.list'
		template: JST['office/templates/messages/deliveries/deliveries']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
			InfiniteScroll:
				scrollable: '.list-wrap'

		ui:
			topbarRightButton: '.topbar-region .right-small'

		events:
			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'

		initialize: =>
			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarRightButtonSpanClass: 'ic-plus-circle'
				tabs: [
					{title: 'Сообщения', href: "/office/#{@options.companyId}/messages/chats"},
					{title: 'Рассылки', href: "/office/#{@options.companyId}/messages/deliveries", active: true}
					{title: 'Добавить отзыв', href: "/office/#{@options.companyId}/messages/reviews"}
				]
				isLoading: false
				isLoadingMore: false
				isEmpty: undefined

			@infiniteScrollState.on 'change:isLoadingMore', (infiniteScrollState, value) =>
				@state.set isLoadingMore: value

			@collection = new Iconto.REST.DeliveryCollection()

		getQuery: =>
			company_id: @state.get('companyId')

		onRender: =>
			#load deliveries

			first = new Iconto.REST.Delivery
				id: _.uniqueId('delivery')
				title: _.uniqueId('title')
				message: _.uniqueId('message')
				created_at: moment().unix()
			second = new Iconto.REST.Delivery
				id: _.uniqueId('delivery')
				title: _.uniqueId('title')
				message: _.uniqueId('message')
				created_at: moment().unix()

#			Q.fcall =>
#				@collection.add first
#				@collection.add second
			@preload()
			.then =>
				@state.set
					isEmpty: @collection.length is 0
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onTopbarRightButtonClick: =>
			Iconto.office.router.navigate "office/#{@options.company.id}/messages/delivery/new", trigger: true

#		onChildviewClick: (view, model) =>
#			Iconto.office.router.navigate "office/#{@options.companyId}/messages/delivery/#{model.get('id')}", trigger: true