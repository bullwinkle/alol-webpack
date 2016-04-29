@Iconto.module 'office.views.messages', (Messages) ->
	class Messages.NewChatView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
		className: 'new-chat-view mobile-layout'
		template: JST['office/templates/messages/chats/new-chat']
		childView: Iconto.office.views.customers.CustomerItemView
		childViewContainer: '.list'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
			InfiniteScroll:
				scrollable: '.list'
				offset: 2000

		ui:
			topbarLeftButton: '.topbar-region .left-small'
			addressSelect: '[name=address-select]'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
			'change .addresses .address input[type=radio]': 'onAddressSelect'

		getQuery: =>
			result =
				company_id: @state.get('companyId')
				is_user: true
			query = @state.get('query')
			result.query = query if query
			result

		initialize: =>
			@collection = new Iconto.REST.CompanyClientCollection()

			@state = new Iconto.office.models.StateViewModel @options
			@state.set
				topbarTitle: 'Новый чат'
				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal,
					leadingComma: true)}"
				isLoading: false

				breadcrumbs: [
					{title: 'Сообщения', href: "/office/#{@options.companyId}/messages/chats"},
					{title: 'Создание нового чата', href: "/office/#{@options.companyId}/messages/chat/new"}
				]

				query: ''
				addresses: []
				selectedAddressId: 0

			@state.addComputed 'showAddressSelector',
				deps: ['addresses'],
				get: (addresses) ->
					addresses.length > 1

			@state.on 'change:query', _.debounce @onStateQueryChange, 300

		onStateQueryChange: (state, query) =>
			@infiniteScrollState.set
				offset: 0
				complete: false
			@collection.reset()
			@preload()

		onRender: =>
			@preload()
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

			(new Iconto.REST.AddressCollection()).fetchAll(company_id: @state.get('companyId'))
			.done (addresses) =>
				@state.set addresses: addresses
				@ui.addressSelect.selectOrDie()

		onChildviewClick: (childView, itemModel) =>
			return false if @onChildviewClickLock
			@onChildviewClickLock = true
			roomView = new Iconto.REST.RoomView()

			reasons = []

			addressId = @state.get('selectedAddressId')
			userId = itemModel.get('user_id')

			if addressId
				reasons.push {type: Iconto.REST.Reason.TYPE_ADDRESS, address_id: addressId}
			else
				reasons.push {type: Iconto.REST.Reason.TYPE_COMPANY, company_id: @options.companyId}

			reasons.push {type: Iconto.REST.Reason.TYPE_USER, user_id: userId}

			roomView.save(reasons: reasons)
			.then (response) =>
				Iconto.office.router.navigate "office/#{@options.companyId}/messages/chat/#{response.id}", trigger: true
			.dispatch(@)
			.catch (error) =>
				console.error error
				#				Iconto.shared.views.modals.ErrorAlert.show error
				switch error.status
					when "ACCESS_DENIED"
						Iconto.shared.views.modals.ErrorAlert.show
							status: '', msg: "Пользователь ограничил круг компаний, которые могут отправлять ему сообщения"
					else
						Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@onChildviewClickLock = false

		#		_onChildviewClick: (childView, itemModel) =>
		#			addressId = @state.get('selectedAddressId')
		#			userId = itemModel.get('user_id')
		#			return false unless userId
		#			room = new Iconto.REST.Room
		#				type: Iconto.REST.Room.TYPE_ROOM_USER2MERCHANT
		#				address_id: addressId
		#				company_id: @state.get('companyId')
		#				user_id: userId
		#			room.save()
		#			.then (room) =>
		#				if room.error
		#					Iconto.shared.views.modals.Alert.show(title: 'Ошибка', message: 'Пользователь ограничил круг компаний, которые могут ему писать.')
		#				else
		#					if room.id
		#						Iconto.office.router.navigate "office/#{@state.get('companyId')}/messages/chat/#{room.id}", trigger: true
		#					else
		#						Iconto.shared.views.modals.Alert.show(title: 'Ошибка', message: 'Ошибка создания чата.')
		#			.catch (error) =>
		#				console.error error
		#				Iconto.shared.views.modals.ErrorAlert.show error
		#			.done()

		onTopbarRightButtonClick: =>
			@trigger 'done', @state.get('filter'), @state.get('contacts')

		onAddressSelect: (e) =>
			$target = $(e.currentTarget)
			id = $target.attr('data-id') - 0
			@state.set 'selectedAddressId', id