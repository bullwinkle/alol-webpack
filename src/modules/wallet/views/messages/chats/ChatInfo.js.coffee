@Iconto.module 'wallet.views.messages', (Messages) ->
	class Messages.ChatInfoView extends Marionette.LayoutView
		className: 'chat-info-view mobile-layout'
		template: JST['wallet/templates/messages/chats/chat-info']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']


		ui:
			topbarLeftButton: '.topbar-region .left-small'
			blockButton: '[name=block]'
			unblockButton: '[name=unblock]'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
			'click @ui.blockButton': 'onBlockButtonClick'
			'click @ui.unblockButton': 'onUnblockButtonClick'

		bindingSources: =>
#			state: =>
#				@state
			company: =>
				@company

		initialize: =>
			@model = new Iconto.REST.Room id: @options.chatId

			@company = new Iconto.REST.Company()

			@state = new Iconto.wallet.models.StateViewModel @options
			@state.set
				topbarLeftButtonClass: ''
				topbarLeftButtonSpanClass: 'ic-chevron-left'

				addresses: []
				blocked: undefined
			@state.addComputed 'showBlocked',
				deps: ['blocked'],
				get: (blocked) ->
					blocked is false
			@state.addComputed 'showUnblocked',
				deps: ['blocked'],
				get: (blocked) ->
					blocked is true

		onRender: =>
			@model.fetch()
			.then (chat) =>
				if _.isEmpty chat
					# chat is blocked or doesnt exist
					Iconto.ws.request('chat:block:list')
					.then (blockedChats) =>
							# search in blocked chats
							chat = _.find blockedChats, (item) =>
								item.room_id is @model.get('id')
							@getChatInfo chat
							@state.set 'blocked', true
				else
					@getChatInfo chat
					@state.set 'blocked', false
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set
					isLoading: false

		getChatInfo: (chat) =>
			@company.set 'id', chat.company_id
			@state.set
				topbarTitle: chat.name || chat.room_name

			addressesCache = []
			addressesPromise = (new Iconto.REST.AddressCollection()).fetchAll(company_id: chat.company_id)
			.then (addresses) =>
					addressesCache = addresses
					(new Iconto.REST.CityCollection()).fetchByIds(_.pluck(addresses, 'city_id'))
			.then (cities) =>
					addresses = addressesCache
					_.each addresses, (address) ->
						addressCity = _.find cities, (city) ->
							city.id is address.city_id
						address.full_address = addressCity.name + ', ' + address.address
					@state.set 'addresses', addresses

			companyPromise = Q.fcall =>
				@company.fetch() unless @company.isNew()

			Q.all [addressesPromise, companyPromise]

		onTopbarLeftButtonClick: =>
			if @state.get 'blocked'
				Iconto.wallet.router.navigate "wallet/messages/chats", trigger: true
			else
				Iconto.wallet.router.navigate "wallet/messages/chat/#{@model.get('id')}", trigger: true

		onBlockButtonClick: =>
			@ui.blockButton.attr 'disabled', true
			Q(Iconto.ws.request('chat:block:add', room_id: @model.get('id')))
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set 'blocked', true
				@ui.blockButton.removeAttr 'disabled'

		onUnblockButtonClick: =>
			@ui.unblockButton.attr 'disabled', true
			Q(Iconto.ws.request('chat:block:remove', room_id: @model.get('id')))
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set 'blocked', false
				@ui.unblockButton.removeAttr 'disabled'
