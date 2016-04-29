@Iconto.module 'office.views.messages', (Messages) ->
	class Messages.ChatView extends Iconto.chat.views.ChatView
		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
				outlets:
					topbar: JST['office/templates/messages/chats/topbar']
			OrderedCollection: {}
			Subscribe: {}

		ui: _.extend ChatView::ui,
			topbarTitle: '.topbar-region .middle-small'

		events: _.extend ChatView::events,
			'click @ui.topbarTitle': 'onTopbarTitleClick'
			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'

		initialize: =>
			super
			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				limit: 10
				offset: 0
				topbarLeftButtonClass: 'hide-on-web-view'
				topbarRightButtonClass: 'text-button'
				topbarLeftButtonSpanClass: 'ic-chevron-left'

				reviewId: 0

			@user = new Iconto.REST.User @options.user
			@roomView = new Iconto.REST.RoomView id: @options.chatId
			@collection = new Iconto.REST.MessageCollection()

			@listenTo Iconto.ws, 'message:received', (data) =>
				@onMessageCreate data

		onRender: =>
			super
			.then =>
				(new Iconto.REST.Group(id: @roomView.get('group_id'))).fetch()
				.then (group) =>
					# show CLOSE REVIEW button if group has review id
					if group.reason.review_id
						@state.set reviewId: group.reason.review_id

						(new Iconto.REST.CompanyReview(id: @state.get('reviewId'))).fetch()
						.then (review) =>
							if review.status is Iconto.REST.CompanyReview.STATUS_OPEN
								@state.set topbarRightButtonSpanText: 'Закрыть отзыв'

					args =
						room_view_ids: [@roomView.get('id')]
						reasons: [group.reason]
					promises = [
						# @subscribe 'EVENT_MESSAGE_CREATE', args, @onMessageCreate
						@subscribe 'EVENT_MESSAGE_READ', args, @onMessageRead
					]
					Q.all(promises)

		onTopbarTitleClick: ->
			@goToClientPage()

		onTopbarLeftButtonClick: =>
			Iconto.shared.router.navigate "office/#{@options.companyId}/messages/chats", trigger: true

		onTopbarRightButtonClick: =>
			# close review
			(new Iconto.REST.CompanyReview(id: @state.get('reviewId'))).save(status: Iconto.REST.CompanyReview.STATUS_RESOLVED)
			.then =>
				@state.set topbarRightButtonSpanText: ''
			.catch (error) ->
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error

		fetchRoom: =>
			@roomView.fetch()
			.then (roomView) =>
				@subscribe 'EVENT_MESSAGE_PRINTED', room_id: @roomView.get('room_id'), @onMessagePrinted

				contactPhone = '+7 ' + Iconto.shared.helpers.phone.format7 roomView.contact_phone

				src = _.get roomView, 'image.url', ''
				if src
					src = Iconto.shared.helpers.image.resize(src, Iconto.shared.helpers.image.FORMAT_SQUARE_SMALL)

				@state.set
					topbarTitle: roomView.name
					topbarSubtitle: roomView.additional_group_names || roomView.source_group_additional_name || contactPhone
					clientPhone: roomView.contact_phone
					isLoading: false

				@getCompanyClient()

			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error

		onChildviewClientClick: (view, clientModel) ->
			@goToClientPage()

		getCompanyClient: ->
			params =
				phone: @state.get 'clientPhone'
				company_id: @state.get 'companyId'

			(new Iconto.REST.CompanyClientCollection()).fetch(params, {reload: true})
			.then (clients) =>
				client =
					id: clients[0].id
					user_id: clients[0].user_id
				@state.set 'client', client
			.catch (err) =>
				err.msg = switch err.status
					when 213109
						'Клиент компании не найден'
					when 200002
						'Данные недоступны'
					else
						err.msg
				console.error err
				@addCompanyClient(params)
			.done()

		goToClientPage: ->
			companyId = @state.get 'companyId'
			client = @state.get('client')
			console.log(client)
			if client.id
				Iconto.shared.router.navigate "/office/#{companyId}/customer/#{client.id}/edit", trigger: true
			else
				Iconto.shared.views.modals.ErrorAlert.show 'Клиент компании не найден'

		addCompanyClient: (fields) =>
			client = new Iconto.REST.CompanyClient fields
			(new client.constructor()).save client.toJSON()
			.then (companyClient) =>
				return false unless companyClient
				_.defer =>
					@state.set 'client', companyClient
			.dispatch(@)
			.catch (err) =>
				console.error err
			.done()