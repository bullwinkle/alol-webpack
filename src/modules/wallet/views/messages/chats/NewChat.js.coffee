@Iconto.module 'wallet.views.messages', (Messages) ->
	class Messages.AddressItemView extends Marionette.ItemView
		tagName: 'div'
		className: 'button address-item list-item'
		template: JST['wallet/templates/messages/chats/address-item']

		events:
			'click [name=info]': 'onInfoClick'
			'click .actions': 'onActionsClick'
			'click .overlay': 'onOverlayClick'
			'click .overlay .send-chat': 'onOverlaySendClick'
			'click .overlay .info-chat': 'onOverlayInfoClick'
			'click': 'onClick'

		findOverlays: =>
			@$el.parent().find('.show-overlay')

		removeOverlays: =>
			@findOverlays().each (index, overlay) =>
				$(overlay).removeClass('show-overlay')

		onClick: (e) =>
#			if @$('[name=info]:visible')
#				@onInfoClick e
#				return false
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

		onOverlaySendClick: (e) =>
			@trigger 'click', @model
			e.stopPropagation()

		onOverlayInfoClick: (e) =>
			Iconto.shared.views.modals.Alert.show
				message: 'Переход на просмотр инфы'
			e.stopPropagation()

		onInfoClick: (e) =>
			console.warn 'click'
			return
			e.stopPropagation()
			Iconto.wallet.router.navigate "/wallet/company/#{@model.get('company_id')}/address/#{@model.get('id')}", trigger: true

	class Messages.NewChatView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
		className: 'new-chat-view mobile-layout'
		template: JST['wallet/templates/messages/chats/new-chat']
		childView: Messages.AddressItemView
		childViewContainer: '.list'

		behaviors:
			Epoxy: {}
			InfiniteScroll:
				scrollable: '.list-wrap'
				offset: 2000
			QueryParamsBinding:
				bindings: [
					model: 'state'
					fields: ['query']
				]

		ui:
			topbarRightButton: '.topbar-region .right-small'
			queryInput: '[name=query]'
			input: '.input input'
			nearby: '.nearby'
#			text: '.input .text'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'
			'change .addresses .address input[type=radio]': 'onAddressSelect'

		getQuery: =>
			result = {}
			query = @state.get('query')
			result.query = query
#			location = @state.get('location')
#			result.location = location if location
#			lat = @state.get 'lat'
#			lon = @state.get 'lon'
#			if lat and lon
#				result.lat = lat
#				result.lon = lon
			result

		collectionEvents: =>
			'add remove reset': =>
				@state.set 'isEmpty', @collection.length is 0

		initialize: =>
			@collection = new Iconto.REST.CompanyCollection()

			@state = new Iconto.wallet.models.StateViewModel @options
			@state.set
				topbarTitle: 'Новый чат'
#				topbarLeftButtonClass: ''
#				topbarLeftButtonSpanClass: 'ic-chevron-left'
				isLoading: false

#				lat: null
#				lon: null

				query: ''
				location: ''

				isLoadingMore: false
				isEmpty: null
				isGeolocationDisabled: false

#			if Iconto.shared.services.media.available
#				@state.set
#					topbarRightButtonClass: 'text-button'
#					topbarRightButtonSpanText: 'QR'

			@state.addComputed 'showNotFoundText',
				deps: ['isLoadingMore', 'isEmpty'],
				get: (isLoadingMore, isEmpty) ->
					isEmpty and not isLoadingMore

			@listenTo @infiniteScrollState, 'change:isLoadingMore', (infiniteScrollState, isLoadingMore) =>
				@state.set 'isLoadingMore', isLoadingMore
			@listenTo @state, 'change:query change:location', _.debounce @onStateQueryChange, 300
#			@listenTo @state, 'change:lat change:lon', @onStateCoordsChange

		onRender: =>
			$('html').on 'click.remove-chats-view-overlays', (e) =>
				@$('.show-overlay').removeClass('show-overlay')
				true

		onShow: =>
			@ui.queryInput.focus()

#			geo = Iconto.shared.services.geo

#			timeOut = setTimeout ( @reload ), 3000 # if getCurrentPosition is not accepted and browser is asking user for acceptance and user can`t see the browser's request, then reload after 6 sec.

#			if geo.available and not (@state.get('lat') and @state.get('lon'))
#
#				geo.getCurrentPosition()
#				.then (position) =>
#					clearTimeout timeOut
#					@collection.reset()
#					@state.set
#						isGeolocationDisabled: false
#						lat: position.coords.latitude
#						lon: position.coords.longitude
#				.catch (error) =>
#					console.error error
#					clearTimeout timeOut
#					switch error.code
#						when geo.ERROR_CODE_PERMISSION_DENIED
#							@state.set isGeolocationDisabled: true
#						when geo.ERROR_CODE_POSITION_UNAVAILABLE
#							'POSITION_UNAVAILABLE'
#						when geo.ERROR_CODE_TIMEOUT
#							'TIMEOUT'
#				.done()
#			else
#				@reload().done()

			@reload().done()

		onStateQueryChange: =>
			if @ui.input.val()
#				@ui.text.hide()
				@ui.nearby.hide()
			else
#				@ui.text.show()
				@ui.nearby.show()
			@reload().done()

#		onStateCoordsChange: =>
#			@reload().done()

		reload: =>
			@infiniteScrollState.set
				offset: 0
				complete: false
			@collection.reset()
			@promise.cancel() if @promise
			@promise = @preload()
			.catch (error) =>
				console.error error
				unless error instanceof Promise.CancellationError
					switch error.status
						when 203402
							@promise.cancel()
							@collection.reset()
							@ui.nearby.addClass('hide')
							@infiniteScrollState.set
								isLoadingMore: false
						else
							Iconto.shared.views.modals.ErrorAlert.show error

		onChildviewClick: (view, model) =>
			return false if @onChildviewClickLock
			@onChildviewClickLock = true

			Iconto.wallet.router.navigate "/wallet/company/#{model.get('id')}", trigger: true

#			roomView = new Iconto.REST.RoomView()
#
#			reasons = []
#			reasons.push {type: Iconto.REST.Reason.TYPE_USER, user_id: @options.user.id}
#			if model.get('company_id')
#				reasons.push {type: Iconto.REST.Reason.TYPE_ADDRESS, address_id: model.get('id')}
#			else
#				reasons.push {type: Iconto.REST.Reason.TYPE_REFERENCE, address_reference: model.get('id')}
#
#			roomView.save(reasons: reasons)
#			.then (response) =>
#				Iconto.wallet.router.navigate "wallet/messages/chat/#{response.id}", trigger: true
#			.dispatch(@)
#			.catch (error) =>
#				console.error error
#				Iconto.shared.views.modals.ErrorAlert.show error
#			.done =>
#				@onChildviewClickLock = false

		onBeforeDestroy: =>
			$('html').off 'click.remove-chats-view-overlays'
			delete @['promise']

		onTopbarRightButtonClick: =>
			if Iconto.shared.services.media.available
				Iconto.wallet.router.navigate "/wallet/messages/chat/new/qr", trigger: true