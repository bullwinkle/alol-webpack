#= require ./ChatItem

@Iconto.module 'chat.views', (Views) ->
	class Views.ChatsView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
		className: 'chats-view mobile-layout'
		template: JST['chat/templates/chats']
		childView: Views.ChatItemView
		childViewContainer: '.list'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
			InfiniteScroll:
				scrollable: '.list'

		ui:
			topbarRightButton: '.topbar-region .right-small'
			notFound: '.not-found'
			noChats: '.no-chats'
			search: '[name=query]'

		events:
			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'

		bindingSources: =>
			infiniteScrollState: @infiniteScrollState

		collectionEvents: =>
			'add remove reset': =>
				@ui.noChats.hide()
				if @state.get('query') and @collection.length is 0
					@ui.notFound.show()
				else
					@ui.notFound.hide()

		initialize: ->
			@listenTo Iconto.events,
				'authorised:false': =>
					console.warn 'unauthorised'
					Iconto.shared.views.modals.PromptAuth.show
						preset: 'unauthorized'
						successCallback: =>
							unless @collection.length
								@rerender()
#					@listenToOnce Iconto.events,'authorised:true', =>
				'internetConnection:lost': =>
				'internetConnection:found': =>

		_loadMore: =>
			Q.fcall =>
				state = @infiniteScrollState.toJSON()
				return false if state.complete

				@infiniteScrollState.set 'isLoadingMore', true

				query = @getQuery()
				queryText = @state.get('query')

				if @deferred and not @deferred.isFulfilled()
					@deferred.cancel()

				@deferred = Q.fcall =>
					if queryText
						query.query = queryText
						Iconto.ws.action('REQUEST_SEARCH', query)
						.then (searchResults) =>
							if searchResults.search_result
								_.map searchResults.search_result, (searchResult) ->
									if searchResult.message
										searchResult.room_view.last_message = searchResult.message
									searchResult.room_view
							else
								[]
					else
						(new Iconto.REST.RoomViewCollection()).fetchAll(query)
				.then (roomViews) =>
					# promise cancel passes undefined here
					roomViews = [] unless roomViews

					@infiniteScrollState.set 'complete', true if roomViews.length < state.limit
					@infiniteScrollState.set
						offset: state.offset + roomViews.length #response.length - actual amount of loaded entities
					# load roomViews
					if roomViews.length > 0
						roomIds = _.unique _.compact _.pluck roomViews, 'room_id'
						(new Iconto.REST.RoomCollection()).fetchAll(ids: roomIds)
						.then (rooms) =>
							user_ids = _.unique _.compact _.map rooms, (room) ->
								room.last_message.user_id if room?.last_message
							search_user_ids = _.unique _.compact _.map roomViews, (roomView) ->
								roomView.last_message.user_id if roomView?.last_message
							user_ids = _.unique _.union user_ids, search_user_ids
							(new Iconto.REST.UserCollection()).fetchByIds(user_ids)
							.then (users) =>
								for roomView in roomViews
									room = _.find rooms, (_room) ->
										_room.id is roomView.room_id
									unless roomView.last_message
										roomView.last_message = if room?.last_message then room.last_message else {}
									# console.warn roomView.last_message, room.last_message
									user = _.find users, (_user) ->
										_user.id is roomView.last_message.user_id if roomView.last_message
									# TODO: handle this shit
									roomView.last_message.user = user
								roomViews
					else
						roomViews
				.then (roomViews) =>
					# promise cancel passes undefined here
					roomViews = [] unless roomViews

					@infiniteScrollState.set isLoadingMore: false
					@loadingLocked = false
					# if @collection.length > 0
					# 	@collection.unshift roomViews
					# else
					# 	@collection.add roomViews.reverse()
					@collection.add roomViews

					if @collection.length is 0 and not @state.get('query')
						@ui.noChats.show?()
					else
						@ui.noChats.hide?()
					roomViews
				.cancellable()

		rerender: =>
			Q.fcall =>
				@onRender()
#			.then =>
#				setTimeout =>
#					@reload()
#				,100

		onRender: =>
			unless _.get Iconto, 'ws.connection.socket.connected'
				@listenToOnce Iconto.ws, 'connected', => @rerender()
				@listenToOnce Iconto.ws, 'reconnected', => @rerender()
				fakePromise = Promise.defer()
				return fakePromise.promise # need to return empty promise

			$('html').on 'click.remove-chats-view-overlays', (e) =>
				@$('.show-overlay').removeClass('show-overlay')
				true

			@preload()
			.dispatch(@)
			.catch (error) =>
				@state.set 'isLoading', false
				console.error error
				if error.status isnt Iconto.shared.services.WebSocket.STATUS_SESSION_EXPIRED
					alertify.error 'websockets error'
			.done =>
				@state.set 'isLoading', false

		onBeforeDestroy: =>
#			clearInterval @sessionInterval
			$('html').off 'click.remove-chats-view-overlays'

		onMessageCreate: (data) =>
			message = data.message
			roomView = data.room_view
			userPromise = (new Iconto.REST.User(id: message.user_id)).fetch()
			.then (user) =>
				message.user = user

				availableRoomView = @collection.get roomView.id
				roomView.last_message = message
				if availableRoomView
					#roomView is already rendered - update
					availableRoomView.set roomView
					@collection.sort()
				else
					#new roomView - render
					@collection.unshift roomView

			receivePromise = Iconto.ws.action 'REQUEST_MESSAGE_RECEIVED',
				sequence_number: message.sequence_number
				room_view_id: roomView.id

			Q.all([userPromise, receivePromise])
			.dispatch(@)
			.catch (error) =>
				console.error 'onMessageCreate', error
			.done()

		onChildviewChangeVisible: (childView, itemModel) =>
			if itemModel.get('visible') is false
				@infiniteScrollState.set offset: @infiniteScrollState.get('offset') - 1
				@collection.remove itemModel

		onChildviewChangeBlocked: (childView, itemModel) =>
			if itemModel.get('blocked') is true
				@infiniteScrollState.set offset: @infiniteScrollState.get('offset') - 1
				@collection.remove itemModel

		reload: =>
#			@state.set isLoading: true
			@collection.reset()
			@infiniteScrollState.set
				complete: false
				offset: 0
			@preload()

		onStateQueryChange: (state, query) =>
			@infiniteScrollState.set 'isLoadingMore', true
			@reload()
			.then =>
				@infiniteScrollState.set 'isLoadingMore', false
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()