@Iconto.module 'chat.views', (Views) ->
	class Views.ChatItemView extends Marionette.ItemView
		tagName: 'div'
		className: 'button chat-item-view list-item'
		template: JST['chat/templates/chat-item']

		ui:
			lastMessageSenderName: '.last-message .sender-name'
			lastMessageBody: '.last-message .message-body'
			senderImage: '.sender-image'
			time: '.date'
			overlayUserInfoButton: '.chat-user-info'
			hideChatButton: '.hide-chat'

		events: =>
			'click .actions': 'onActionsClick'
			'click .overlay': 'onOverlayClick'
			'click .overlay .block-chat': 'onOverlayLockClick'
			'click @ui.hideChatButton': 'onOverlayHideClick'
			'click @ui.overlayUserInfoButton': 'onOverlayUserInfoClick'
			'click': 'onClick'

		templateHelpers:
			imageWidth: 20
			getDateString: (time) ->
				momentTime = moment(Math.floor(time / 1000))
				showTime = not momentTime.isBefore(moment().startOf('day'))
				if showTime
					momentTime.format('HH:mm')
				else
					momentTime.format('DD MMM YYYY')

			getMessageBody: (message) ->
				if message.attachments and message.attachments.length > 0
					Iconto.REST.Attachment.getTypeString(message.attachments[0].type)
				else
					message.body || ''

		modelEvents:
			'change:last_message': ->
				message = @model.get('last_message')
				@ui.lastMessageSenderName.text message.sender_name

				@ui.lastMessageBody.text @templateHelpers.getMessageBody(message)

				if message.user and message.user.image
					@ui.senderImage.attr 'src', "#{message.user.image.url}?resize=[#{@templateHelpers.imageWidth}]"
				else
					@ui.senderImage.removeAttr 'src'
				@ui.time.text @templateHelpers.getDateString(message.created_at)
			'change:unread_amount': 'checkUnreadMessages'

		initialize: =>
			@checkUnreadMessages()

		findOverlays: =>
			@$el.parent().find('.show-overlay')

		removeOverlays: =>
			@findOverlays().each (index, overlay) =>
				$(overlay).removeClass('show-overlay')

		checkUnreadMessages: =>
			if @model.get('unread_amount') > 0
				@$el.addClass 'has-unread-messages'
			else
				@$el.removeClass 'has-unread-messages'

		onClick: (e) =>
			$overlays = @findOverlays()
			unless $overlays.length > 0
				@trigger 'click', @model
			else
				$overlays.each (index, overlay) =>
					$(overlay).removeClass('show-overlay')
				e.stopPropagation()

		onActionsClick: (e) =>
			@removeOverlays()
			@$el.addClass 'show-overlay'
			e.stopPropagation()

		onOverlayClick: (e) =>
			@$el.removeClass 'show-overlay'
			e.stopPropagation()

		onOverlayHideClick: (e) =>
			Iconto.shared.views.modals.Confirm.show
				message: 'Вы действительно хотите скрыть этот чат?'
				onSubmit: =>
					@$el.removeClass 'show-overlay'
					@model.setVisible(false)
					.then (response) =>
						if response.status is true
							@model.set visible: false
							@trigger 'change:visible', @model
						else
							throw 'Не удалось скрыть чат'
					.dispatch(@)
					.catch (error) =>
						console.error error
						Iconto.shared.views.modals.ErrorAlert.show error
					.done()
				onCancel: =>
					@$el.removeClass 'show-overlay'
			e.stopPropagation()

		onOverlayLockClick: (e) =>
			Iconto.shared.views.modals.Confirm.show
				message: 'Вы действительно хотите заблокировать этот чат?'
				onSubmit: =>
					@$el.removeClass 'show-overlay'
					@model.setBlocked(true)
					.then (response) =>
						if response.status is true
							@model.set blocked: true
							@trigger 'change:blocked', @model
						else
							throw 'Не удалось заблокировать чат'
					.dispatch(@)
					.catch (error) =>
						console.error error
						if error.status.toLowerCase() is 'access_denied'
							error.msg = 'Вы не можете заблокировать этот чат'
						Iconto.shared.views.modals.ErrorAlert.show error
					.done()
				onCancel: =>
					@$el.removeClass 'show-overlay'
			e.stopPropagation()

		onOverlayUserInfoClick: =>
			model = @model.toJSON()
			console.warn 'RoomView', model
			return unless model.room_id

			groups = new Iconto.REST.GroupCollection()

			groups.fetch(room_id: model.room_id)
			.then (groups) =>
				merchantGroup =  _.findWhere groups, role: "ROLE_MERCHANT"
				userGroup =  _.findWhere groups, role: "ROLE_USER"

				userId = if _.isObject(userGroup.reason) and userGroup.reason.user_id
					userGroup.reason.user_id
				companyId = if _.isObject(merchantGroup.reason) and merchantGroup.reason.company_id
					merchantGroup.reason.company_id

				if userId and companyId
					@getCompanyClient(userId, companyId)
					.then (client)=>
						route = "/office/#{companyId}/customer/#{client.id}/edit"
						Iconto.shared.router.navigate route, trigger: true
					.catch (err) =>
						throw err

			.catch (err) =>
				console.error err
				err.msg = switch err.status
					when 213109
						'Клиент компании не найден'
					when 200002
						'Данные не доступны'
					else
						'Пользователь не определен'
				err.message = err.msg
				Iconto.shared.views.modals.ErrorAlert.show err
			.done()

		getCompanyClient: (userId, companyId) =>
			params =
				user_id: userId
				company_id: companyId
			(new Iconto.REST.CompanyClientCollection()).fetch(params, {reload: true})
			.then (clients)=>
				clients[0]
