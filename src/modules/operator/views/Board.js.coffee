#= require ../models/ChatListItemModel
#= require ./MessageItem
#= require chat/views/Submit

@Iconto.module 'operator.views', (Views) ->
	class UserInfoModal extends Marionette.ItemView
		template: JST['operator/templates/user-info']
		className: 'user-info-view'

		behaviors:
			Epoxy: {}

		ui:
			select: 'select'
			saveButton: '[name=save-button]'
			cancelButton: '[name=cancel-button]'

		events:
			'click @ui.saveButton': 'onSaveButtonClick'
			'click @ui.cancelButton': 'onCancelButtonClick'

		initialize: ->
			@model = new Iconto.REST.CompanyClient(id: @options.contactId)

		onRender: ->
			@model.fetch()
			.then =>
				@model.set
					first_name: @model.get('first_name_display')
					last_name: @model.get('last_name_display')

				hasName = !!((@model.get('first_name') + @model.get('last_name')).trim())
				unless hasName
					@model.set first_name_display: "Аноним ##{@model.get('user_id')}"

				@ui.select.selectOrDie('update')
				@buffer = @model.clone()

		onSaveButtonClick: ->
			fields = (new Iconto.REST.CompanyClient(@buffer.toJSON())).set(@model.toJSON()).changed

			unless _.isEmpty fields
				@model.save(fields)
				.then =>
					@trigger 'destroy'
				.catch (error) ->
					console.error error

		onCancelButtonClick: ->
			@trigger 'destroy'

	class EmployeeItemView extends Marionette.ItemView
		template: JST['operator/templates/employee-item']
		className: 'employee flexbox flex-v-center'

		attributes: ->
			'data-user-id': @model.get('user_id')

		triggers:
			'click': 'click'

		initialize: ->
			# set nickname
			nickname = @model.get('user').nickname || "Пользователь ##{@model.get('id')}"
			@model.set nickname: nickname

	class EmployeeCollectionView extends Marionette.CollectionView
		childView: EmployeeItemView

		onChildviewClick: (view) ->
			# remove active class
			@$('.employee.active').removeClass('active')
			view.$el.addClass('active')

			# store current active user id
			@activeUserId = view.model.get('user_id')

	class EmployeeSelectModal extends Marionette.LayoutView
		template: JST['operator/templates/employee-select']
		className: 'employee-select-view'

		regions:
			employeesRegion: '.employees'

		ui:
			transferButton: '[name=transfer-button]'
			cancelButton: '[name=cancel-button]'

		events:
			'click @ui.transferButton': 'onTransferButtonClick'
			'click @ui.cancelButton': 'onCancelButtonClick'

		initialize: ->
			@collection = new Iconto.REST.ContactCollection()

		onRender: ->
			@collection.fetchAll(company_id: @options.companyId, {silent: true})
			.then (employees) =>
				# remove current user
				employees = _.without employees, _.findWhere employees, user_id: Iconto.api.userId

				# get user ids
				userIds = _.uniq _.compact _.pluck employees, 'user_id'

				# populate w/ users
				(new Iconto.REST.UserCollection()).fetchByIds(userIds)
				.then (users) =>
					_.each employees, (employee) =>
						employee.user = _.findWhere users, id: employee.user_id

					# reset collection
					@collection.reset employees

					# show contacts
					@employeesRegion.show new EmployeeCollectionView collection: @collection.clone()
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error

		onTransferButtonClick: ->
			# get current active user id
			userId = @employeesRegion.currentView.activeUserId

			# trigger event
			if userId
				@trigger 'user:selected', userId

		onCancelButtonClick: ->
			@trigger 'destroy'

	class MessagesView extends Marionette.CollectionView
		childView: Iconto.operator.views.MessageItemView

	class ChatInfoView extends Marionette.LayoutView
		template: JST['operator/templates/chat-info']
		className: 'chat-info flexbox'

		behaviors:
			Epoxy: {}

		ui:
			user: '.user-info'
			closeButton: '.close-button'
			transferButton: '.transfer-button'

		events:
			'click @ui.user': 'onUserClick'
			'click @ui.closeButton': 'onCloseButtonClick'
			'click @ui.transferButton': 'onTransferButtonClick'

		bindingSources: ->
			client: @client
			group: @group
			review: @review
			company: @company
			operator: @operator

		initialize: ->
			@model = new Iconto.REST.RoomView(id: @options.chatId)

			@client = new Iconto.REST.CompanyClient()
			@group = new Iconto.REST.Group()
			@review = new Iconto.REST.CompanyReview
				id: 0
				className: 'ic ic-face-smile'
				name: ''
			@company = new Iconto.REST.Company()
			@operator = new Iconto.REST.User()

		onRender: ->
			# get chat info
			@model.fetch()
			.then =>
				if @model.get('operator_id')
					@operator.set(id: @model.get('operator_id')).fetch()
				@group.set(id: @model.get('group_id')).fetch()
			.then =>
				@review.set
					name: @group.get('additional_name').split(' ')[0]
					className: 'ic ' + @getReviewClassName()
				@company.set(id: @group.get('reason').company_id).fetch()
			.then =>
				params =
					query: @model.get('contact_phone')
					company_id: @group.get('reason').company_id
				(new Iconto.REST.CompanyClientCollection()).fetch(params)
			.then (client) =>
				if client.length is 1
					client = client[0]
					@client.set client
			.then =>
				reviewId = @group.get('reason').review_id
				if reviewId
					@review.set(id: reviewId).fetch()

		getReviewClassName: ->
			className = 'ic-face-smile'
			className = 'ic-face-sad' unless @group.get('additional_name').indexOf('Печалька') is -1
			className = 'ic-idea' unless @group.get('additional_name').indexOf('Хотелка') is -1
			className

		onUserClick: ->
			lbx = Iconto.shared.views.modals.LightBox.show
				view: UserInfoModal
				options:
					contactId: @client.get('id')

		onCloseButtonClick: ->
			params =
				title: 'Завершение чата'
				message: 'Вы уверены, что хотите завершить чат?'
				onSubmit: =>
					@closeChat()

			if @review.get('id')
				params =
					title: 'Завершение чата'
					message: 'Вы уверены, что хотите завершить чат и закрыть отзыв?'
					onSubmit: =>
						@closeChat()
						@closeReview()

			Iconto.shared.views.modals.Confirm.show params

		closeChat: ->
			@model.setOperator(0)
			.then =>
				@operator.clear()
				Iconto.shared.router.navigate 'operator', trigger: true
			.catch (error) ->
				console.error error

		closeReview: ->
			@review.save(status: Iconto.REST.CompanyReview.STATUS_RESOLVED)
			.catch (error) ->
				console.error error

		onTransferButtonClick: ->
			companyId = @group.get('reason').company_id

			if companyId
				lbx = Iconto.shared.views.modals.LightBox.show
					view: EmployeeSelectModal
					options:
						companyId: companyId

				@listenTo lbx,
					'user:selected': ([userId]) =>
						@model.setOperator(userId)
						.then =>
							lbx.destroy()
							@operator.set(id: userId).fetch()
						.then ->
							Iconto.shared.router.navigate 'operator', trigger: true
						.catch (error) ->
							console.error error

	class HistoryLayout extends Marionette.LayoutView
		template: JST['operator/templates/history']
		className: 'history-view'
		attributes: ->
			'data-has-chat': => !!@options.chatId

		behaviors:
			InfiniteScroll:
				inverted: true
				offset: 50
				scrollable: '#messages'

		regions:
			chatInfoRegion: '#chat-info'
			submitRegion: '#submit'

		ui:
			messages: '#messages'
			messagesContainer: '.messages'

		initialize: ->
			@model = new Iconto.REST.RoomView(id: @options.chatId)

			@messagesScrollState = new Backbone.Model
				limit: 30
				offset: 0
				isLoading: false
				isCompleted: false

		onShow: ->
			if @model.get('id')

				@model.fetch()
				.then =>
					# check if we need to set operator
					@checkOperator()

					# get group for reasons to check review id
					(new Iconto.REST.Group(id: @model.get('group_id'))).fetch()
				.then (group) =>
					# check rating to render submit form
					reviewId = _.get(group, 'reason.review_id', 0)
					if reviewId
						(new Iconto.REST.CompanyReview(id: reviewId)).fetch()
						.then (review) =>
							if review.rating is Iconto.REST.CompanyReview.RATING_NONE
								# show submit input
								@renderSubmitView()
					else
						# show submit input
						@renderSubmitView()
				.then =>

					# get first messages
					@getMessages()

				.then (messages) =>
					# send message read event
					if messages.length and @model.get('unread_amount')
						@sendMessageRead(_.last(messages).sequence_number)

				.then =>
					# show chat info
					@chatInfoRegion.show new ChatInfoView(chatId: @options.chatId)

				.catch (error) ->
					console.error error
					if error.status is Iconto.shared.services.WebSocket.STATUS_INTERNAL_ERROR
						Iconto.shared.router.navigate 'operator', trigger: true

				# attach events (image click, go to chat, etc.)
				@attachEvents()

		checkOperator: ->
			# if chat has unread messages and no operator,
			# then take this chat (set operator id = user id)
			if @model.get('unread_amount') and @model.get('operator_id') is 0
				@model.setOperator(@options.user.id)
				.catch (error) ->
					console.error error

		sendMessageRead: (sequenceNumber) ->
			# send message read
			Iconto.ws.action 'REQUEST_MESSAGE_READ',
				sequence_number: sequenceNumber
				room_view_id: @model.get('id')

		renderSubmitView: ->
			submitView = new Views.SubmitView
				room_id: @options.chatId
				chatId: @options.chatId
				user: @options.user
			@listenTo submitView, 'add-message-request', @sendMessage

			@submitRegion.show submitView

		sendMessage: (message) ->
			delete message.id
			(new Iconto.REST.Message()).save(message)
			.then (m) =>
				model = @addMessage m
			.dispatch(@)
			.catch (error) =>
				console.error error
				model.set notDelivered: true
			.done()

		appendMessage: (message) ->
			$lastMessage = $('.message-item-view', @ui.messagesContainer).last()
			userId = $lastMessage.data('user-id')
			roomViewId = $lastMessage.data('room-view-id')

			message.user ||= @options.user
			user = message.user
			messageView = new Views.MessageItemView
				model: new Iconto.REST.Message message
				user: user
				sameAuthor: ((userId is user.id) and (message.room_view_id is roomViewId))
			messageView.render()

			# prepend then to messages container element
			@ui.messagesContainer.append messageView.el

			# scroll to bottom or to new scroll height
			@ui.messages.scrollTo @ui.messagesContainer.height()

			@sendMessageRead(message.sequence_number)

		addMessage: (message) ->
			@appendMessage(message)
			@trigger 'message:submit', message

		attachEvents: ->
			@attachOnImageClick()

			@attachOnGoToCompanyReviewChat()

		attachOnImageClick: ->
			@ui.messagesContainer.on 'click', '.attachment.image img', (e) ->
				imageSrc = $(e.currentTarget).attr('src')
				return false unless imageSrc
				imgSrcObj = Iconto.shared.helpers.navigation.parseUri imageSrc
				delete imgSrcObj.search # need to work with .query
				delete imgSrcObj.query.resize
				imgSrcFull = imgSrcObj.format()
				Iconto.shared.views.modals.LightBox.show
					img: imgSrcFull

		attachOnGoToCompanyReviewChat: ->
			@ui.messagesContainer.on 'click', '.go-to-company-review-chat', (e) ->
				reviewId = $(e.currentTarget).data('company-review-id')

				params =
					reviewId: reviewId
					fromOffice: true

				(new Iconto.REST.CompanyReview(id: reviewId)).fetch()
				.then (companyReview) ->
					params.userId = companyReview.user_id

					Iconto.shared.helpers.messages.openChat(params)
					.then (response) ->
						Iconto.shared.router.navigate "operator/chat/#{response.id}", trigger: true

		loadReviews: ->
			# get info about reviews
			# thnx God, only one review in one chat ^_^
			reviews = $('[data-review-loaded="false"]', @ui.messagesContainer)
			reviews.each ->
				$review = $(@)
				reviewId = $review.data('review-id')

				if reviewId
					(new Iconto.REST.CompanyReview(id: reviewId)).fetch()
					.then (review) ->
						$review.addClass("rating-#{review.rating}")
					.catch (error) ->
						console.error error

		getMessages: ->
			(new Iconto.REST.MessageCollection()).fetchAll(@getQuery())
			.then (messages) =>
				# get company info
				companyIds = _.uniq _.compact _.map messages, 'company_id'

				Promise.try ->
					if companyIds.length
						(new Iconto.REST.CompanyCollection()).fetchByIds(companyIds)
					else
						return []
				.then (companies) =>
					# populate with company if needed
					if companyIds.length
						_.each messages, (message) ->
							if message.type in [Iconto.REST.Message.PRODUCER_TYPE_COMPANY, Iconto.REST.Message.PRODUCER_TYPE_DELIVERY]
								message.company = _.find companies

					# create collection
					collection = new Iconto.REST.MessageCollection messages

					# create view
					messagesView = new MessagesView collection: collection

					# get inner html, message items (messages)
					messagesHTML = messagesView.render().el.innerHTML

					# origin height
					originHeight = @ui.messagesContainer.height()

					# prepend then to messages container element
					@ui.messagesContainer.prepend messagesHTML

					# load review data
					@loadReviews()

					# scroll to bottom or to new scroll height
					@ui.messages.scrollTo @ui.messagesContainer.height() - originHeight

					# update scroll state
					@messagesScrollState.set
						offset: @messagesScrollState.get('offset') + @messagesScrollState.get('limit')
						isLoading: false
						isCompleted: messages.length < @messagesScrollState.get('limit')

					messages

		getQuery: ->
			# generate query params for messages request
			room_view_id: @model.get('id')
			limit: @messagesScrollState.get('limit')
			offset: @messagesScrollState.get('offset')
			order:
				field: 'sequence_number'
				direction: 'ORDER_DIRECTION_DESC'

		onInfiniteScroll: ->
			# prevent multiple requests
			return false if @messagesScrollState.get('isLoading') or @messagesScrollState.get('isCompleted')

			# set isLoading
			@messagesScrollState.set isLoading: true

			# get new messages
			@getMessages()

	class ChatListItemView extends Marionette.ItemView
		template: JST['operator/templates/chatlist-item']
		className: 'chat flexbox'
		attributes: ->
			'data-room-view-id': @model.get('id')

		templateHelpers: ->
			getDateString: =>
				model = @model.toJSON()
				time = _.get(model, 'room.last_message.created_at', _.get(model, 'room.created_at'))
				return '' unless time
				momentTime = moment(Math.floor(time / 1000))
				formatString = 'DD.MM.YYYY'
				formatString = 'HH:mm' unless momentTime.isBefore(moment().startOf('day'))
				momentTime.format formatString

			getTimeString: =>
				model = @model.toJSON()
				time = _.get(model, 'room.last_message.created_at', _.get(model, 'room.created_at'))
				return '' unless time
				momentTime = moment(Math.floor(time / 1000))
				momentTime.format('HH:mm')

			getLastMessage: =>
				model = @model.toJSON()
				lastMessage = _.get model, 'room.last_message'

				# return is no messages
				unless lastMessage
					return 'Нет сообщений'

				# if has any attachment detect type
				if lastMessage.attachments and lastMessage.attachments.length
					attachment = lastMessage.attachments[0]
					return Iconto.REST.Attachment.getTypeString(attachment.type)

				# if has user
				if lastMessage.type is Iconto.REST.Message.PRODUCER_TYPE_USER
					name = lastMessage.user.nickname or lastMessage.user.name
					if lastMessage.type is Iconto.REST.Message.PRODUCER_TYPE_USER
						return "#{name.split(' ')[0]}: #{lastMessage.body}"

				# if any troubles return body
				return lastMessage.body

			getReviewClassName: =>
				model = @model.toJSON()
				className = 'ic-face-smile'
				className = 'ic-face-sad' unless model.group.additional_name.indexOf('Печалька') is -1
				className = 'ic-idea' unless model.group.additional_name.indexOf('Хотелка') is -1
				className

		ui:
			chatOperatorName: '.chat-operator-name'

		events:
			'click': 'onClick'

		initialize: ->
			@listenTo @model, 'change', @render

		onRender: ->
			if @model.get('id') is @options.selectedChat
				@$el.addClass('selected')

			operatorId = @model.get('operator_id')
			if operatorId
				(new Iconto.REST.User(id: operatorId)).fetch()
				.then (user) =>
					@ui.chatOperatorName.text user.nickname
				.dispatch(@)

		onClick: ->
			Iconto.shared.router.navigate "operator/chat/#{@model.get('id')}", trigger: true

	class NoChatListView extends Marionette.ItemView
		template: JST['operator/templates/no-chatlist']
		className: 'no-chats flexbox flex-v-center flex-h-center'

		initialize: ->
			@model.set _.defaults @options, emptyViewMessage: 'Нет чатов'

	class ChatListView extends Marionette.CollectionView
		childView: ChatListItemView
		emptyView: NoChatListView

		emptyViewOptions: ->
			emptyViewMessage: @options.emptyViewMessage

		childViewOptions: ->
			_.pick @options, 'selectedChat'

		reorderOnSort: true

		viewComparator: (model1, model2) ->
			m1 = model1.toJSON()
			m2 = model2.toJSON()

			createdAt1 = _.get(m1, 'room.last_message.created_at', _.get(m1, 'room.created_at'))
			createdAt2 = _.get(m2, 'room.last_message.created_at', _.get(m2, 'room.created_at'))

			if createdAt1 > createdAt2
				return -1
			if createdAt1 < createdAt2
				return 1
			return 0

	class Views.BoardView extends Marionette.LayoutView
		template: JST['operator/templates/board']
		className: 'mobile-layout board-view'

		behaviors:
			Epoxy: {}
			Layout: {}
			Subscribe: {}
			InfiniteScroll:
				scrollable: '.chats-wrap'

		regions:
			myChatsRegion:
				el: '#my-chats'
				emptyViewMessage: 'Нет чатов, закрепленных за Вами'
			queueChatsRegion:
				el: '#queue-chats'
				emptyViewMessage: 'Нет чатов в очереди'
			otherChatsRegion:
				el: '#other-chats'
				emptyViewMessage: 'Нет закрытых чатов, либо закрепленных за другими сотрудниками'
			historyRegion:
				el: '#history'

		initialize: ->
			@state = new Iconto.operator.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Сообщения'
				isLoading: false

			# room views scroll state
			@roomViewsScrollState = new Backbone.Model
				limit: 5
				offset: 0
				isLoading: false
				isCompleted: false

			# current user
			@user = new Iconto.REST.User(@options.user)

			# all my companies
			@companies = new Iconto.REST.CompanyCollection()

			# room view collection
			@roomViews = new Iconto.REST.RoomViewCollection()

			# rooms collection
			@rooms = new Iconto.REST.RoomCollection()

			# groups collection
			@groups = new Iconto.REST.GroupCollection()

		onShow: ->
			if _.get(Iconto.ws, 'connection.socket.connected')
				console.info 'OPERATORS: Socket connected. Updating chats...'
				@updateChats()

			@listenTo Iconto.ws, 'connected', =>
				console.info 'OPERATORS: Chat connected. Updating chats...'

				@updateChats()

				@historyRegion.show(new HistoryLayout(chatId: @options.chatId, user: @options.user))
				@listenTo @historyRegion.currentView, 'message:submit', @onMessageSubmit

			@listenTo Iconto.ws, 'reconnected', ->
				console.info 'OPERATORS: Chat reconnected.'

			@listenTo @state, 'change', (state) ->
				state = state.changed
				@historyRegion.show(new HistoryLayout(chatId: state.chatId, user: @options.user))
				@listenTo @historyRegion.currentView, 'message:submit', @onMessageSubmit

				@setSelectedChat()

		updateChats: ->
			@companies.fetchAll(filters: ['my'])
			.then (companies) =>
				if companies
					Promise.all([@getMyChats(), @getQueueChats(), @getOtherChats()])
			.then =>
				@subscribeChats()

		getMyChats: ->
			query =
				limit: 30
				offset: 0
				reasons: @getReasons()
				operator_id: @user.get('id')
				visibility: true

			@getChats query, @myChatsRegion

		getQueueChats: ->
			query =
				limit: 50
				offset: 0
				reasons: @getReasons()
				operator_id: 0
				has_unread: true
				visibility: true

			@getChats query, @queueChatsRegion

		getOtherChats: ->
			query =
				limit: @roomViewsScrollState.get('limit')
				offset: @roomViewsScrollState.get('offset')
				reasons: @getReasons()
				visibility: true
				operator_id: -1

			@getChats query, @otherChatsRegion
			.then (roomViews) =>

				# set defaults
				@roomViewsScrollState.set
					offset: @roomViewsScrollState.get('offset') + @roomViewsScrollState.get('limit')
					isLoading: false
					isCompleted: roomViews.length < @roomViewsScrollState.get('limit')

				# check scroll height
				$scrollable = @$(@behaviors.InfiniteScroll.scrollable)
				if $scrollable.prop('scrollHeight') <= $scrollable.outerHeight() and not @roomViewsScrollState.get('isCompleted')
					@onInfiniteScroll()

		getChats: (query, region) ->
			_roomViews = []

			@roomViews.fetchAll(query)
			.then (roomViews) =>
				_roomViews = roomViews

				# get rooms with last message
				roomIds = _.unique _.compact _.pluck roomViews, 'room_id'
				roomsPromise = @rooms.fetchAll(ids: roomIds)

				# get groups with reason info
				groupsPromise = @groups.fetchAll(reasons: @getReasons())

				Promise.all([roomsPromise, groupsPromise])
			.spread (rooms, groups) ->

				# merge rooms and groups into roomViews
				_.each _roomViews, (roomView) =>
					roomView.room = _.findWhere rooms, id: roomView.room_id
					roomView.group = _.findWhere groups, id: roomView.group_id

			.catch (error) =>
				console.error error

				# reset room views for empty state to appear instead loading
				_roomViews = []

			.then =>

				# if region has view, add to collection with merge
				# else show new view
				if region.hasView()
					region.currentView.collection.add _roomViews, {merge: true}
				else
					chatListView = new ChatListView
						collection: (new Iconto.REST.RoomViewCollection(_roomViews))
						emptyViewMessage: region.options.emptyViewMessage
						selectedChat: @options.chatId
					region.show chatListView

				# return room views to count
				_roomViews

		subscribeChats: ->
			# group update
			@subscribe 'EVENT_GROUP_UPDATE', reasons: @getReasons(), @onGroupUpdate

			# message create
			@subscribe 'EVENT_MESSAGE_CREATE', reasons: @getReasons(), @onMessageCreate

			# change operator
			@subscribe 'EVENT_ROOM_VIEW_CHANGE_OPERATOR', reasons: @getReasons(), @onRoomViewChangeOperator

		onGroupUpdate: (args) =>
			console.warn 'onGroupUpdate', args

			type = args.type
			group = args.group
			roomView = null
			regions = [@myChatsRegion, @queueChatsRegion, @otherChatsRegion]

			if type is Iconto.REST.Group.UPDATE_TYPE_UNREADAMOUNT
				for region in regions

					# detect room view
					roomView = region.currentView.collection.findWhere group_id: group.id

					if roomView
						# set unread_amount from group
						roomView.set unread_amount: group.unread_amount

		onMessageSubmit: (message) ->
			console.warn 'onMessageSubmit', message

			roomView = message.room_view
			regions = [@myChatsRegion, @queueChatsRegion, @otherChatsRegion]

			for region in regions

				# set new info and trigger change to rerender only once
				chat = region.currentView.collection.findWhere(id: roomView.id)

				if chat
					chat.get('room').last_message = message
					chat.set(unread_amount: roomView.unread_amount, {silent: true})
					chat.trigger('change')
					region.currentView.resortView()

		onMessageCreate: (args) =>
			console.warn 'onMessageCreate', args

			message = args.message
			roomView = args.room_view

			(new Iconto.REST.User(id: message.user_id)).fetch()
			.then (user) =>
				message.user = user

				# detect chats region, e.g. myChatsRegion, queueChatsRegion, otherChatsRegion
				region = @otherChatsRegion

				if roomView.operator_id is @user.get('id')
					# operator id is user id => my chats
					region = @myChatsRegion
				else if roomView.operator_id is 0 and roomView.unread_amount > 0
					# no operator id and has unread messages =>
					region = @queueChatsRegion

				# set new info and trigger change to rerender only once
				chat = region.currentView.collection.findWhere(id: roomView.id)

				if chat
					chat.get('room').last_message = message
					unless @historyRegion.hasView() and @historyRegion.currentView.options.chatId is roomView.id
						chat.set(unread_amount: roomView.unread_amount, {silent: true})
					chat.trigger('change')
					region.currentView.resortView()

				else
					groupPromise = (new Iconto.REST.Group(id: roomView.group_id)).fetch()
					roomPromise = (new Iconto.REST.Room(id: roomView.room_id)).fetch()

					Promise.all([groupPromise, roomPromise])
					.spread (group, room) =>
						roomView.group = group
						roomView.room = room

						region.currentView.collection.unshift roomView
						region.currentView.resortView()

				# update history messages if chat is open
				if @historyRegion.hasView() and @historyRegion.currentView.options.chatId is roomView.id
					@historyRegion.currentView.appendMessage message

		onRoomViewChangeOperator: (args) =>
			console.warn 'onRoomViewChangeOperator', args

			operatorId = args.operator_id
			roomViewId = args.room_view_id
			regions = [@myChatsRegion, @queueChatsRegion, @otherChatsRegion]

			myChatsCollection = @myChatsRegion.currentView.collection
			queueChatsCollection = @queueChatsRegion.currentView.collection
			otherChatsCollection = @otherChatsRegion.currentView.collection

			roomView = null

			if operatorId is 0
				# Two possible options
				# 1. Chat is in my chats -> move to other chats and change operator id (I close the chat)
				# 2. Chat is in other chats -> change operator id (some one has closed the chat)

				# 1. Chat is in my chats -> move to other chats and change operator id
				roomView = myChatsCollection.findWhere id: roomViewId
				if roomView
					myChatsCollection.remove roomView
					otherChatsCollection.add roomView
					roomView.set operator_id: operatorId
					@otherChatsRegion.currentView.resortView()

				# 2. Chat is in other chats -> change operator id
				roomView = otherChatsCollection.findWhere id: roomViewId
				if roomView
					roomView.set operator_id: operatorId

			else if operatorId is Iconto.api.userId
				# Two possible options
				# 1. Chat is in queue chats -> move to my chats and change operator id (I take chat)
				# 2. Chat is in other chats -> move to my chats and change operator id (someone set me as operator)

				# 1. Chat is in queue chats -> move to my chats and change operator id (I take chat)
				roomView = queueChatsCollection.findWhere id: roomViewId
				if roomView
					queueChatsCollection.remove roomView
					myChatsCollection.add roomView
					roomView.set operator_id: operatorId
					@myChatsRegion.currentView.resortView()

				# 2. Chat is in other chats -> move to my chats and change operator id (someone set me as operator)
				roomView = otherChatsCollection.findWhere id: roomViewId
				if roomView
					otherChatsCollection.remove roomView
					myChatsCollection.add roomView
					roomView.set operator_id: operatorId
					@myChatsRegion.currentView.resortView()

			else
				# Three possible options (operator_id != 0 and operator_id != user_id)
				# 1. Chat is in my chats -> move to other chats and change operator id (I change operator, e.g. from %my_user_id% to 3748)
				# 2. Chat is in queue chats -> move to other chats and change operator id (someone has taken a chat, e.g. from 0 to 748)
				# 3. Chat is in other chats -> change operator id (someone has changed operator, e.g. from 647 to 837)

				# 1. Chat is in my chats -> move to other chats and change operator id (I change operator, e.g. from %my_user_id% to 3748)
				roomView = myChatsCollection.findWhere id: roomViewId
				if roomView
					myChatsCollection.remove roomView
					otherChatsCollection.add roomView
					roomView.set operator_id: operatorId
					@otherChatsRegion.currentView.resortView()

				# 2. Chat is in queue chats -> move to other chats and change operator id (someone has taken a chat, e.g. from 0 to 748)
				roomView = queueChatsCollection.findWhere id: roomViewId
				if roomView
					queueChatsCollection.remove roomView
					otherChatsCollection.add roomView
					roomView.set operator_id: operatorId
					@otherChatsRegion.currentView.resortView()

				# 3. Chat is in other chats -> change operator id (someone has changed operator, e.g. from 647 to 837)
				roomView = otherChatsCollection.findWhere id: roomViewId
				if roomView
					roomView.set operator_id: operatorId

			@setSelectedChat()

		getReasons: ->
			reasons = @companies.map (company) ->
				type: Iconto.REST.Reason.TYPE_COMPANY_AGGREGATED
				company_id: company.get('id')

		setSelectedChat: ->
			@$('.chat.selected').removeClass('selected')
			if @state.get('chatId')
				@$(".chat[data-room-view-id=#{@state.get('chatId')}]").addClass('selected')

		onInfiniteScroll: ->
			# prevent multiple requests
			return false if @roomViewsScrollState.get('isLoading') or @roomViewsScrollState.get('isCompleted')

			# set isLoading
			@roomViewsScrollState.set isLoading: true

			@getOtherChats()