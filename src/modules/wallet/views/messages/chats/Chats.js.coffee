@Iconto.module 'wallet.views.messages', (Messages) ->

	class Messages.ChatItemView extends Iconto.chat.views.ChatItemView
		template: JST['wallet/templates/messages/chats/chat-item']

	class Messages.ChatsView extends Iconto.chat.views.ChatsView #Iconto.shared.views.infinite.BaseInfiniteCompositeView
		template: JST['chat/templates/chats']
		childView: Messages.ChatItemView
		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
			InfiniteScroll:
				scrollable: '.list-wrap'
#			Subscribe:
#				'EVENT_MESSAGE_CREATE':
#					args: ->
#						reasons: [
#							type: Iconto.REST.Reason.TYPE_USER
#							user_id: @options.user.id
#						]
#					handler: 'onMessageCreate'

		initialize: ->
			super
			@state = new Iconto.wallet.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Сообщения'
				collectionLength: 0
				query: ''

			@listenTo @state, 'change:query', @onStateQueryChange

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
				@state.set collectionLength: collection.length

			@listenTo Iconto.ws, 'message:received', @onMessageCreate

		onChildviewClick: (childView, itemModel) =>
			route = "wallet/messages/chat/#{itemModel.get('id')}"
			Iconto.wallet.router.navigate route, trigger: true

		getQuery: =>
			limit: @infiniteScrollState.get('limit')
			offset: @infiniteScrollState.get('offset')
			visibility: true
			reasons: [
				type: Iconto.REST.Reason.TYPE_USER
				user_id: @options.user.id
			]

		onTopbarRightButtonClick: =>
#			Iconto.wallet.router.navigate "wallet/messages/chat/new", trigger: true