@Iconto.module 'office.views.messages', (Messages) ->
	class Messages.ChatsView extends Iconto.chat.views.ChatsView
		template: JST['chat/templates/chats']
		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
			InfiniteScroll:
				scrollable: '.list-wrap'

		initialize: =>
			super
			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				isLoading: false
#				topbarTitle: 'Сообщения'
#				topbarSubtitle: "#{@options.company.name}, #{Iconto.REST.LegalEntity.LEGAL_TYPES[@options.legal.type - 1]} \"#{@options.legal.name}\""
				topbarRightButtonSpanClass: 'ic-pencil-square'
				query: ''

				tabs: [
					{title: 'Сообщения', href: "/office/#{@options.companyId}/messages/chats", active: true},
					{title: 'Рассылки', href: "/office/#{@options.companyId}/messages/deliveries"}
					{title: 'Добавить отзыв', href: "/office/#{@options.companyId}/messages/reviews"}
				]
			@state.on 'change:query', @onStateQueryChange
			@collection = new Iconto.REST.RoomViewCollection()
			@collection.comparator = (prevModel, nextModel) =>
				prev =  prevModel.get 'updated_at'
				next =  nextModel.get 'updated_at'
				if prev is next
					return 0
				else if prev > next # descending order
					return -1
				else
					return 1

			@listenTo @collection, 'update', (collection, options) =>
				if collection.length is 0 and !@state.get('query')
					@ui.search.hide()
				else
					@ui.search.show()
			@listenTo Iconto.ws, 'message:received', @onMessageCreate

		onChildviewClick: (childView, itemModel) =>
			route = "office/#{@options.company.id}/messages/chat/#{itemModel.get('id')}"
			Iconto.office.router.navigate route, trigger: true

		getQuery: =>
			limit: @infiniteScrollState.get('limit')
			offset: @infiniteScrollState.get('offset')
			visibility: true
			reasons: [
				type: Iconto.REST.Reason.TYPE_COMPANY_AGGREGATED
				company_id: @options.company.id
			]

		onTopbarRightButtonClick: =>
			Iconto.office.router.navigate "office/#{@options.company.id}/messages/chat/new", trigger: true