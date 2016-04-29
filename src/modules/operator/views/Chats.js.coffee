@Iconto.module 'operator.views', (Views) ->
	class Views.ChatsView extends Iconto.chat.views.ChatsView
		template: JST['operator/templates/chats']
		childView: Views.ChatItemView
		childViewOptions: =>
			groups: @groups.toJSON()
		behaviors:
			Epoxy: {}
			Layout: {}
			InfiniteScroll:
				scrollable: '.list-wrap'
			Subscribe:
				'EVENT_GROUP_UPDATE':
					args: ->
						reasons: _.map @options.companyIds, (id) ->
							type: Iconto.REST.Reason.TYPE_COMPANY_AGGREGATED
							company_id: id
					handler: 'onGroupUpdate'

				'EVENT_MESSAGE_CREATE':
					args: ->
						reasons: _.map @options.companyIds, (id) ->
							type: Iconto.REST.Reason.TYPE_COMPANY_AGGREGATED
							company_id: id
					handler: 'onMessageCreate'

				'EVENT_ROOM_VIEW_CHANGE_OPERATOR':
					args: ->
						reasons: _.map @options.companyIds, (id) ->
							type: Iconto.REST.Reason.TYPE_COMPANY_AGGREGATED
							company_id: id
					handler: 'onRoomViewChangeOperator'

		initialize: ->
			@state = new Iconto.operator.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Сообщения'
				isLoading: true
				query: ''
				unreadAmount: 0

			@listenTo @state,
				'change:query': @onStateQueryChange
				'change:page': @onStatePageChange

			@collection = new Iconto.REST.RoomViewCollection()
			@collection.comparator = (prevModel, nextModel) =>
				prev = prevModel.get 'updated_at'
				next = nextModel.get 'updated_at'
				if prev is next
					return 0
				else if prev > next # descending order
					return -1
				else
					return 1

			@groups = new Iconto.REST.GroupCollection()

		rerender: ->
			Q.fcall =>
				@onRender()

		onRender: ->
			unless _.get Iconto, 'ws.connection.socket.connected'
				@listenToOnce Iconto.ws, 'connected', => @rerender()
				@listenToOnce Iconto.ws, 'reconnected', => @rerender()
				fakePromise = Promise.defer()
				return fakePromise.promise # need to return empty promise

			reasons = _.map @options.companyIds, (id) ->
				type: Iconto.REST.Reason.TYPE_COMPANY_AGGREGATED
				company_id: id

			@groups.fetchAll(reasons: reasons)
			.then (groups) =>
				super

		onChildviewClick: (childView, itemModel) =>
			# if room view has unread messages and doesnt have operator id
			if itemModel.get('unread_amount') > 0 and itemModel.get('operator_id') is 0
				itemModel.setOperator(@options.user.id)
				.then (response) =>
					route = "operator/chat/#{itemModel.get('id')}"
					Iconto.operator.router.navigate route, trigger: true
				.dispatch(@)
				.catch (error) =>
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()
			else
				route = "operator/chat/#{itemModel.get('id')}"
				Iconto.operator.router.navigate route, trigger: true

		getQuery: =>
			state = @state.toJSON()

			reasons = _.map state.companyIds, (id) ->
				type: Iconto.REST.Reason.TYPE_COMPANY_AGGREGATED
				company_id: id

			query =
				limit: @infiniteScrollState.get('limit')
				offset: @infiniteScrollState.get('offset')
				reasons: reasons
			if state.page is 'unread'
				query.has_unread = true
				query.operator_id = 0
			query.operator_id = @options.user.id if state.page is 'taken'
			query

		onTopbarRightButtonClick: =>
			Iconto.operator.router.navigate "operator", trigger: true

		onStatePageChange: =>
			@state.set query: ''
			@reload()
			.then =>
				@state.set isLoading: false

		onMessageCreate: (data) =>
			console.group()
			console.warn 'Chats message create', data
			console.warn 'Room view unread amount', data.room_view.unread_amount
			console.warn 'Room view operator id', data.room_view.operator_id
			console.groupEnd()

			message = data.message
			roomView = data.room_view

			# Messages check unread amount
			# ============================
			# If room_view.unread_amount = 1,
			# it means that room room view changed its status,
			# so we have to add +1 to message counters.
			# To decide where to add +1 we have to check operator_id.

			if roomView.unread_amount is 1
				if roomView.operator_id
					if roomView.operator_id is @options.user.id
						App.commands.execute 'messages:taken:change', 1
				else
					App.commands.execute 'messages:unread:change', 1
			# Done.

			userPromise = (new Iconto.REST.User(id: message.user_id)).fetch()
			.then (user) =>
				message.user = user
				availableRoomView = @collection.get roomView.id
				roomView.last_message = message

				if availableRoomView
					# roomView is already rendered - update
					availableRoomView.set roomView
					@collection.sort()
				else
					# new roomView - render
					if @state.get('page') is 'all'
						# add anyway
						@collection.unshift roomView
					if @state.get('page') is 'taken'
						if roomView.operator_id is @options.user.id
							# taken and operator id is mine
							@collection.unshift roomView
					if @state.get('page') is 'unread'
						unless roomView.operator_id
							# render only operatorless room views
							@collection.unshift roomView

			receivePromise = Iconto.ws.action 'REQUEST_MESSAGE_RECEIVED',
				message_ids: [message.id]
				room_view_id: roomView.id

			Q.all([userPromise, receivePromise])
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onGroupUpdate: (data) =>
			console.warn 'Chats group update', data

			# This handler is used only to decrease counters.
			# It checks available room view and if there is no available room view,
			# it sends event messages:recount with handler in Layout view.

			# find room view with such group id
			availableRoomView = @collection.findWhere group_id: data.group.id

			if availableRoomView
				# has room

				if data.group.unread_amount is 0
					# unread amount is 0, means that room has been read

					if @state.get('page') is 'unread'
						# remove message if on unread page
						@collection.remove availableRoomView

						# change unread count
						App.commands.execute 'messages:unread:change', -1

					if @state.get('page') is 'taken'
						# change unread amount
						availableRoomView.set unread_amount: 0

						# change taken messages count
						App.commands.execute 'messages:taken:change', -1

					if @state.get('page') is 'all'
						# set unread amount
						availableRoomView.set unread_amount: 0

						if availableRoomView.get('operator_id') is @options.user.id
							# taken count changed
							App.commands.execute 'messages:taken:change', -1
						if availableRoomView.get('operator_id') is 0
							# change taken messages count
							App.commands.execute 'messages:unread:change', -1
			else
				if data.type is Iconto.REST.Group.UPDATE_TYPE_UNREADAMOUNT and data.group.unread_amount is 0
					# recount only if unread amount is 0 which means that messages have been read
					App.commands.execute 'messages:recount' # handler in Layout


		onRoomViewChangeOperator: (data) =>
			availableRoomView = @collection.get data.room_view_id
			operatorId = data.operator_id

			if availableRoomView
				if operatorId
					(new Iconto.REST.User(id: operatorId)).fetch()
					.then (user) =>
						availableRoomView.set operator_id: operatorId
					.catch (error) ->
						console.error error
					.done()
				else
					availableRoomView.set operator_id: operatorId