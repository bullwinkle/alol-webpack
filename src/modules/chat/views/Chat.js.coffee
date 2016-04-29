#= require ./MessageItem
#= require ./Submit

@Iconto.module 'chat.views', (Views) ->
	class Views.ChatView extends Marionette.CompositeView
		className: 'chat-view mobile-layout'
		template: JST['chat/templates/chat']
		childView: Views.MessageItemView
		childViewContainer: '.messages .list'

		behaviors:
			Epoxy: {}
			OrderedCollection: {}
			Subscribe: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		ui:
			topbarLeftButton: '.topbar-region .left-small'
			topbarRightButton: '.topbar-region .right-small'
			messages: '.messages'
			formSubmitRegion: '.form-submit-region'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'

		dates: {}

		bindingSources: =>
			sharedState: @sharedState
			roomView: @roomView
			user: @user

		constructor: ->
			super
			@sharedState = new Backbone.Epoxy.Model()
			@sharedState.set printing: {} #structure: user_id: { name: '', timeout: int}
			@sharedState.addComputed 'printingText',
				deps: ['printing']
				get: (printing) ->
					keys = _.keys printing
					length = keys.length
					if length is 0
						return ''
					else if length is 1
						name = printing[keys[0]].name
						return "#{ name } печатает..."
					else
						declension = Iconto.shared.helpers.declension(keys.length,
							['пользователь печатает...', 'пользователя печатают...', 'пользователей печатает...'])
						return "#{length} #{declension}"

			@on 'before:destroy', =>
				clearTimeout data.timeout for user_id, data of @state.get 'printing'
		#				clearInterval @sessionInterval

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
			@listenToOnce Iconto.events,
				'internetConnection:lost': @lostConnectionHander

		lostConnectionHander: =>
			@listenToOnce Iconto.events, 'internetConnection:found', =>
				@listenToOnce Iconto.events, 'internetConnection:lost', @lostConnectionHander
				@preload()
				.dispatch(@)
				.catch (err) =>
					console.error err
				.done =>
					console.warn 'preload'

		childViewOptions: =>
			user: @options.user
			roomViewId: @options.chatId
			readSequenceNumber: @roomView.get('read_sequence_number')
			dates: @dates
			companyId: @options.companyId or 0

		rerender: =>
			Q.fcall =>
				@onRender()

		onRender: =>
			unless _.get Iconto, 'ws.connection.socket.connected'
				@listenToOnce Iconto.ws, 'connected', => @rerender()
				@listenToOnce Iconto.ws, 'reconnected', => @rerender()
				fakePromise = Promise.defer()
				return fakePromise.promise # need to return empty promise

			Iconto.notificator.setFilter 'tag',
				value: @options.chatId
				env: Iconto.shared.services.Notification.ENV_PAGE

			@onMessagesScrollLock = true
			@preload()
			.dispatch(@)
			.catch (err) =>
				console.error err
			.done =>
				@state.set 'isLoading', false
				if @ui.messages instanceof jQuery
					@ui.messages.on 'scroll.infinite-scroll', @onMessagesScroll
				_.defer =>
					@onMessagesScrollLock = false

			@fetchRoom()
			.then (state) =>
				@renderSubmitForm state
			.dispatch(@)

		onMessageCreate: (data) =>
			# detect, if this  message for this or for another chat
			unless @options.chatId is _.get(data, 'room_view.id')
				return false

			message = data.message
			model = @addMessage(message)

			dataPromise = Q.fcall =>
				switch message.type
					when Iconto.REST.Message.PRODUCER_TYPE_USER
						if message.user_id
							(new Iconto.REST.User(id: message.user_id)).fetch()
							.then (user) =>
								model.set 'user', user
					when Iconto.REST.Message.PRODUCER_TYPE_COMPANY, Iconto.REST.Message.PRODUCER_TYPE_DELIVERY
						if message.company_id
							(new Iconto.REST.Company(id: message.company_id)).fetch()
							.then (company) =>
								model.set 'company', company

			console.warn message.sequence_number

			receivePromise = Iconto.ws.action 'REQUEST_MESSAGE_RECEIVED',
				sequence_number: message.sequence_number
				room_view_id: data.room_view.id

			readPromise = Q.fcall =>
				unless data.message.room_view_id is data.room_view.id and data.message.read_at
					#message is from another room_view and is not read yet
					@readMessages @collection.at(0).toJSON().sequence_number, @roomView.toJSON()

			Q.all([dataPromise, receivePromise, readPromise])
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()


		readMessages: (sequenceNumber, roomView) =>
			Iconto.ws.action 'REQUEST_MESSAGE_READ',
				sequence_number: sequenceNumber
				room_view_id: roomView.id
			.then =>
				Iconto.events.trigger 'message:read', sequenceNumber, roomView

		onMessageRead: (data) =>
			readSequenceNumber = 0
			for messageId in data.message_ids
				message = @collection.get(messageId)
				unless message then continue
				message.set 'read_at', Math.floor(data.read_at / 1000)
				if message.get('sequence_number') > readSequenceNumber
					readSequenceNumber = message.get('sequence_number')
			if readSequenceNumber
				@roomView.set('read_sequence_number', readSequenceNumber)

		addMessage: (message) =>
			# add model to the bottom of the chat
			model = @collection.add message, at: 0
			if @ui.messages instanceof jQuery
				_.result @ui, 'messages.scrollToBottom'
			model

		fetchRoom: =>
			@roomView.fetch()
			.then (roomView) =>
				@subscribe 'EVENT_MESSAGE_PRINTED', room_id: @roomView.get('room_id'), @onMessagePrinted

				src = _.get roomView, 'image.url', ''
				if src
					src = Iconto.shared.helpers.image.resize(src, Iconto.shared.helpers.image.FORMAT_SQUARE_SMALL)

				@state.set
					topbarTitle: roomView.name
					topbarSubtitle: roomView.additional_group_names
					isLoading: false
					topbarRightLogoUrl: src

				roomView
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error

		getQuery: =>
			room_view_id: @roomView.get('id')
			limit: @state.get('limit')
			offset: @state.get('offset')
			order:
				field: 'sequence_number'
				direction: 'ORDER_DIRECTION_DESC'

		onBeforeDestroy: =>
			Iconto.notificator.unsetFilter 'tag'

			_.result @chatSubmitView, 'destroy'
			if @ui.messages instanceof jQuery
				@ui.messages.off 'scroll.infinite-scroll'

		preload: =>
			@loadMore()
			.then =>
				return true unless @ui.messages instanceof jQuery
				_.result @ui, 'messages.scrollToBottom'
				if @ui.messages.prop('scrollHeight') <= @ui.messages.outerHeight() and not @state.get('complete')
					@preload()
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error

		loadMore: =>
			Q.fcall =>
				return true if @state.get('complete')

				(new Iconto.REST.MessageCollection()).fetchAll(@getQuery())
				.then (messages = []) =>
					@state.set
						complete: messages.length < @state.get('limit')
						offset: (@state.get('offset') + @state.get('limit'))

					messages.reverse()
					models = @collection.add messages

					#send message read
					roomViewId = @roomView.get('id')

					if @collection.length > 0
						@readMessages @collection.at(0).toJSON().sequence_number, @roomView.toJSON()

					#load companies
					companyMessages = _.filter messages, (m) ->
						m.type in [Iconto.REST.Message.PRODUCER_TYPE_COMPANY, Iconto.REST.Message.PRODUCER_TYPE_DELIVERY]
					companyIds = _.unique _.pluck companyMessages, 'company_id'

					(new Iconto.REST.CompanyCollection()).fetchByIds(companyIds)
					.then (companies) ->
						for model in models
							type = model.get('type')
							if type in [Iconto.REST.Message.PRODUCER_TYPE_COMPANY, Iconto.REST.Message.PRODUCER_TYPE_DELIVERY]
								company = _.find companies, (c) -> c.id is model.get('company_id')
								model.set 'company', company
						undefined

					#return unshifted
					models

		renderSubmitForm: () =>
			rendered = _.get @, 'chatSubmitView.isRendered'
			return false if rendered

			options = _.extend {}, @options, room_id: @roomView.get('room_id')
			@chatSubmitView = new Views.SubmitView options
			@chatSubmitView.render()
			@chatSubmitView.on 'add-message-request', (message) =>
				@sendMessage message

			appendChatSubmitView = =>
				try
					@ui.formSubmitRegion.append @chatSubmitView.$el
					return true
				catch err
					console.warn 'couldn`t renderSubmitForm:', err
					return false
			unless appendChatSubmitView()
				setTimeout appendChatSubmitView, 500

		sendMessage: (message) =>
			model = @addMessage message
			delete message.id
			(new Iconto.REST.Message()).save(message)
			.then (m) =>
				model.set(m)
			.dispatch(@)
			.catch (error) =>
				console.error error
				model.set notDelivered: true
			.done()

		onMessagesScroll: (e) =>
			return true unless @ui.messages instanceof jQuery
			if @ui.messages.scrollTop() <= 1000
				return false if @onMessagesScrollLock
				@onMessagesScrollLock = true

				do =>
					scrollTop = _.result @, 'ui.messages.scrollTop', 0
					scrollHeight = if @ui.messages instanceof jQuery then @ui.messages.prop('scrollHeight') else 0
					@loadMore()
					.dispatch(@)
					.catch (error) =>
						console.error error
					.done =>
						if @ui.messages instanceof jQuery
							delta = @ui.messages.prop('scrollHeight') - scrollHeight
							@ui.messages.scrollTop scrollTop + delta
						@onMessagesScrollLock = false
				true

		onChildviewResend: (childView, itemModel) =>
			message = itemModel.toJSON()
			@collection.remove itemModel
			message.id = _.uniqueId('temp')
			delete message.notDelivered
			@sendMessage(message)

		onMessagePrinted: (data) =>
			if data.user_id
				user = new Iconto.REST.User(id: data.user_id)
				user.fetch()
				.then =>
					printing = @sharedState.get('printing') #DO NOT _.clone!
					if printing[data.user_id]
						#already has an entry for this user - he's already printing - just update the timeout
						clearTimeout printing[data.user_id].timeout
						printing[data.user_id].timeout = setTimeout =>
							cloned = _.clone @sharedState.get('printing')
							delete cloned[data.user_id]
							@sharedState.set 'printing', cloned
						, 3000
					else
						#no entry - create it - and set timeout
						cloned = _.clone printing
						cloned[data.user_id] =
							name: user.get('name') or user.get('nickname')
							timeout: setTimeout =>
								cloned = _.clone @sharedState.get('printing')
								delete cloned[data.user_id]
								@sharedState.set 'printing', cloned
							, 3000
						@sharedState.set 'printing', cloned

		onChildviewReviewClick: ->
			@ui.formSubmitRegion.empty()