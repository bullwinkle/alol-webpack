#= require ./Factory

@Iconto.module 'wallet.views', (Views) ->
	class Views.Layout extends Marionette.LayoutView
		className: 'iconto-layout iconto-wallet-layout'
		template: JST['wallet/templates/layout']

		behaviors:
			Epoxy: {}
			Subscribe: {}

		bindings: # {} #needs to be overridden for child views to work
			'.header .avatar': "attr: { src:resize(get(user_image, 'url'), Iconto.shared.helpers.image.FORMAT_SQUARE_SMALL) }"
			'.header .user-name': "text:format('$1 $2', user_first_name, user_last_name)"
			'.user-profile-image-background': "css: { 'background-image': format('url($1)', resize(get(user_image, 'url')) )}"
			'.user-profile .user-profile-image img': "attr: { src:resize(get(user_image, 'url')) }"
			'.user-profile .user-profile-name': "text: format('$1 $2', user_first_name, user_last_name)"
			'.user-profile .user-profile-phone': "text: format('+7 $1', phoneFormat7(user_phone))"
			'.menu [name=messages]': "classes: { 'show-notification':unread_amount }"

			'.user-profile-messages': 'toggle: unread_amount'
			'.user-profile-messages-count': 'text: unread_amount'
			'.user-profile-messages-text span': "text: declension(unread_amount, ['диалог', 'диалога', 'диалогов'])"

		ui:
			offCanvasWrap: '.off-canvas-wrap'
			messages: '.menu [name=messages]'
			terms: '.menu [name=terms]'
			money: '.menu [name=money]'
			userProfile: '.menu [name=user-profile]'
			offers: '.menu [name=offers]'
			office: '.menu [name=office]'
			registrator: '.menu [name=registrator]'
			services: '.menu [name=services]'
			logoutButton: '[name=logout]'

		events:
			'click .menu a, .user-profile a': 'onOffCanvasLinkClick'
			'click @ui.logoutButton': 'onLogoutButtonClick'

		#		regions:
		#			mainRegion: '#main-region'

		bindingSources: ->
			user: @user

		initialize: =>
			@viewModel = new Iconto.wallet.models.StateViewModel @options #for bindings
			@viewModel.set 'unread_amount', 0
			@state = new Backbone.Model(@options) #for UpdatableRegion
			@state.on 'change', @update

			@user = new Iconto.REST.User()

			Iconto.commands.setHandler 'user:image:change', (url) =>
				@user.set image:
					url: url

			@addRegions
				mainRegion: new Iconto.shared.views.updatableregion.UpdatableRegion(el: '#main-region')
				slideableRegionLeft: new Iconto.shared.views.updatableregion.UpdatableRegion(el: '#slideable-region-left', animate: true)
				slideableRegionRight: new Iconto.shared.views.updatableregion.UpdatableRegion(el: '#slideable-region-right', animate: true)
				slideableRegionRight2: new Iconto.shared.views.updatableregion.UpdatableRegion(el: '#slideable-region-right2', animate: true)

		onRender: =>
			$('body').addClass('wallet')
			@listenTo Iconto.events, 'message:read', @onGlobalMessageRead

			@update()
			.then =>
				if @user.get('id')
					if _.get Iconto, 'ws.connection.socket.connected'
						@subscribeRequired()
						true
					else
						@listenTo Iconto.ws, 'connected', @subscribeRequired.bind @
						true

			.dispatch(@)
			.catch (error) =>
				console.error error
				if error.status isnt Iconto.shared.services.WebSocket.STATUS_SESSION_EXPIRED
					Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				window.layout = @

		subscribeRequired: =>
			reason =
				type: Iconto.REST.Reason.TYPE_USER
				user_id: @user.get('id')

			(new Iconto.REST.GroupCollection()).fetchAll({reasons: [reason]})
			.then (groups) =>
				aux = (acc, group) ->
					acc + group.unread_amount
				unreadAmount = _.reduce groups, aux, 0
				@viewModel.set 'unread_amount', unreadAmount
			.then =>
				subscriptions = [
					@subscribe 'EVENT_GROUP_UPDATE', reasons: [reason], @onGroupUpdate
					@subscribe 'EVENT_MESSAGE_CREATE', reasons: [reason], @onMessageCreate
				]
				Q.all subscriptions
				.dispatch(@)
				.catch (error) =>
					console.error error

		updateLinks: =>
			@$('aside .menu div').removeClass('active')
			switch @state.get('page')
				when 'messages'
					@ui.messages.addClass 'active'
				when 'terms', 'tariffs'
					@ui.terms.addClass 'active'
				when 'money'
					@ui.money.addClass 'active'
				when 'user-profile'
					@ui.userProfile.addClass 'active'
				when 'offers'
					@ui.offers.addClass 'active'
				when 'registrator'
					@ui.registrator.addClass 'active'
				when 'services'
					@ui.services.addClass 'active'

		update: =>
			@updateLinks()
			state = @state.toJSON()
			ViewClass = Views.factory(state)

			updateOptions = @options.updateOptions or {}

			Iconto.api.auth()
			.then (user) =>
				#				Iconto.commands.execute 'workspace:authorised'
				#				Iconto.commands.execute 'workspace:fullscreen:disable'
				@user.set user
				state.user = user
				Iconto.notificator.setFilter 'data.userId', value: user.id

				region = @getRegion(state)
				if region
					if state.forceShow
						region.show new ViewClass(state)
					else
						region.showOrUpdate ViewClass, state
				else
					console.error 'mainRegion is not defined'

			.catch (error) =>
				console.error error
				#				Iconto.commands.execute 'workspace:unauthorised'
				#				Iconto.commands.execute 'workspace:fullscreen:enable'

				region = @getRegion(state)
				if region
					region.showOrUpdate ViewClass, state
				else
					console.error 'mainRegion is not defined'


		getRegion: (state) =>
			viewClassName = Views.factory(state).name

			switch _.get state, 'updateOptions.position'
				when 'right'
					console.info "Showing #{viewClassName} in region RIGHT"
					@slideableRegionRight.empty()
					@slideableRegionRight
				when 'right2'
					console.info "Showing #{viewClassName} in region RIGHT2"
					@slideableRegionRight2.empty()
					@slideableRegionRight2
				when 'left'
					console.info "Showing #{viewClassName} in region LEFT"
					@slideableRegionLeft.empty()
					@slideableRegionLeft
				else
					console.info "Showing #{viewClassName} in region MAIN"
					if @slideableRegionRight?.isVisible()
						@slideableRegionRight.hide()
					if @slideableRegionRight2?.isVisible()
						@slideableRegionRight2.hide()
					if @slideableRegionLeft?.isVisible()
						@slideableRegionLeft.hide()

					@mainRegion

		onShow: =>
			$(document).foundation()

		onOffCanvasLinkClick: (e) =>
			@ui.offCanvasWrap.removeClass 'move-right'

		onMessageCreate: (data) =>
			Iconto.ws.trigger 'message:received', data

			currentUnreadAmount = @viewModel.get 'unread_amount'
			@viewModel.set 'unread_amount', currentUnreadAmount + 1

			roomViewId = _.get data, 'room_view.id'

			messageType = _.get data, 'message.type'
			systemMessage = messageType is Iconto.REST.Message.PRODUCER_TYPE_SYSTEM

			attachments = _.get(data, 'message.attachments', [])
			messageBody = if attachments.length > 0
				attachmentType = _.get(data, 'message.attachments[0].type')
				attachmentTypeString = Iconto.REST.Attachment.getTypeString attachmentType
				"#{attachmentTypeString}"
			else
				_.get data, 'message.body'

			notificationData =
				userId: _.get data, 'message.user_id'

			defer = =>
				Iconto.notificator.notify
					body: messageBody
					title: _.get data, 'room_view.name'
					icon: _.get data, 'room_view.image.url'
					tag: roomViewId
					timeout: 7
					data: notificationData
					onClick: =>
						# dirty hack to force page reload when redirecting from one chat to another
						intermediateRoute = "/wallet/messages/chats"
						route = "/wallet/messages/chat/#{roomViewId}"
						Iconto.shared.router.navigate intermediateRoute, trigger: true
						Iconto.shared.router.navigate route, trigger: true
			setTimeout defer, 100

		onGlobalMessageRead: (sequenceNumber, roomView) =>
			currentUnreadAmount = @viewModel.get 'unread_amount'
			@viewModel.set 'unread_amount', if currentUnreadAmount <= 0 then 0 else currentUnreadAmount

		onGroupUpdate: (data) =>
			@onGroupUpdateDebounced ||= _.debounce (data) =>
				if data.type is Iconto.REST.Group.UPDATE_TYPE_UNREADAMOUNT
					@viewModel.set 'unread_amount', data.group.unread_amount
			, 1000
			@onGroupUpdateDebounced(data)

		onBeforeDestroy: =>
			$('body').removeClass('wallet')
			Iconto.notificator.unsetFilter 'data.userId'
