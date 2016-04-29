@Iconto.module 'shared.views.userProfile', (UserProfile) ->
	class RoomItemView extends Marionette.ItemView
		template: JST['shared/templates/user-profile/blacklist-item']
		className: 'button blacklist-item-view list-item flexbox'

		ui:
			unblockButton: '.unblock-button'

		events:
			'click @ui.unblockButton': 'onUnblockButtonClick'

		onUnblockButtonClick: =>
			isBlocked = @ui.unblockButton.hasClass('blue')

			if isBlocked
				@setBlocked(false)
			else
				Iconto.shared.views.modals.Confirm.show
					message: 'Вы действительно хотите заблокировать этот чат?'
					onSubmit: =>
						@setBlocked(true)

		setBlocked: (value) =>
			@model.setBlocked(value)
			.then =>
				text = 'Разблокировано'
				buttonClass = 'green filled'
				if value
					text = 'Разблокировать'
					buttonClass = 'blue'

				@ui.unblockButton.removeClass('blue green filled').addClass(buttonClass).text(text)
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert error
			.done()

	class UserProfile.BlacklistView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
		className: 'blacklist-view mobile-layout'
		template: JST['shared/templates/user-profile/blacklist']
		childView: RoomItemView
		childViewContainer: '.blacklist'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
			InfiniteScroll:
				scrollable: '.blacklist'

		ui:
			topbarLeftButton: '.topbar-region .left-small'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'

		initialize: =>
			@model = new Iconto.REST.User @options.user
			@collection = new Iconto.REST.RoomViewCollection()

			@state = new Iconto.shared.models.BaseStateViewModel _.extend {}, @options,
				topbarTitle: 'Заблокированные контакты'
				topbarLeftButtonClass: ''
				topbarLeftButtonSpanClass: 'ic-chevron-left'

		onRender: =>
			@preload()
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set 'isLoading', false

		getQuery: =>
			reasons: [
				type: Iconto.REST.Reason.TYPE_USER,
				user_id: @options.user.id
			]
			blocked: true

		onTopbarLeftButtonClick: =>
			url = Backbone.history.fragment.split('/').slice(0, 2).join('/')
			Iconto.shared.router.navigate url, trigger: true

		onChildviewClick: (childView, itemModel) =>
			url = "/wallet/messages/chat/#{itemModel.get('room_id')}/info"
			Iconto.shared.router.navigate url, trigger: true