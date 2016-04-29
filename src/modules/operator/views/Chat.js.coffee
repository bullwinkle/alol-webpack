@Iconto.module 'operator.views', (Views) ->
	class Views.ChatView extends Iconto.chat.views.ChatView
		behaviors:
			Epoxy: {}
			Layout:
				outlets:
					topbar: JST['operator/templates/topbar']
			OrderedCollection: {}
			Subscribe: {}

		ui: _.extend @:: ui,
			chatReleaseButton: '.chat-release'
			middleSmall: '.middle-small'
			rightButton: '.right-small'

		events: _.extend @:: events,
			'click @ui.rightButton': 'onChatReleaseButtonClick'
			'click @ui.middleSmall': 'onMiddleSmallButtonClick'

		initialize: ->
			@state = new Iconto.operator.models.StateViewModel _.extend {}, @options,
				limit: 10
				offset: 0
				operatorId: 0
				topbarLeftButtonClass: ''
				topbarLeftButtonSpanClass: 'ic-chevron-left'
				topbarRightButtonClass: 'is-visible text-button'

			@user = new Iconto.REST.User @options.user
			@roomView = new Iconto.REST.RoomView id: @options.chatId
			@group = new Iconto.REST.Group()
			@collection = new Iconto.REST.MessageCollection()

			@listenTo @roomView, 'change:operator_id', (model, value) =>
				@state.set operatorId: value

		onRender: ->
			super
			.then =>
				@group.set(id: @roomView.get('group_id')).fetch()
				.then (group) =>
					args =
						room_view_ids: [@roomView.get('id')]
						reasons: [group.reason]
					messageCreate = @subscribe 'EVENT_MESSAGE_CREATE', args, @onMessageCreate
					messageRead = @subscribe 'EVENT_MESSAGE_READ', args, @onMessageRead
					Q.all([messageCreate, messageRead])

		fetchRoom: ->
			@roomView.fetch()
			.then (roomView) =>
				@subscribe 'EVENT_MESSAGE_PRINTED', room_id: @roomView.get('room_id'), @onMessagePrinted

				src = if roomView.image and roomView.image.id
					Iconto.shared.helpers.image.resize(roomView.image.url, Iconto.shared.helpers.image.FORMAT_SQUARE_SMALL)
				else
					Iconto.shared.helpers.image.anonymous()

				@state.set
					topbarTitle: roomView.name
					topbarSubtitle: roomView.additional_group_names || roomView.source_group_additional_name
					isLoading: false
					topbarRightLogoUrl: src

				if roomView.operator_id is @options.user.id
					@state.set topbarRightButtonSpanText: 'Отпустить'

			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error

		onChatReleaseButtonClick: ->
			@roomView.setOperator(0)
			.then =>
				Iconto.operator.router.navigate 'operator/taken', trigger: true
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onTopbarLeftButtonClick: ->
			Iconto.shared.router.navigateBack('operator/all')

		onMiddleSmallButtonClick: ->
			params =
				query: @roomView.get('contact_phone')
				company_id: @group.get('reason').company_id

			(new Iconto.REST.CompanyClientCollection()).fetch(params)
			.then (clients) ->
				route = "office/#{params.company_id}/customers"
				if clients.length
					client = clients[0]
					route = "office/#{params.company_id}/customer/#{client.id}/edit"
					Iconto.shared.router.navigate route, trigger: true
				else
					Iconto.shared.views.modals.Alert.show
						title: 'Клиент не найден'
						message: 'Клиент с номером телефона +7 ' + Iconto.shared.helpers.phone.format7(params.query) + ' не найден в списке клиентов компании.'
			.catch (error) =>
				console.error error
				error.msg = 'К сожалению, '
				Iconto.shared.views.modals.ErrorAlert.show error