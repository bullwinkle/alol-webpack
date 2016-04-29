#= require ./Factory

@Iconto.module 'office.views', (Views) ->
	class LayoutViewModel extends Backbone.Epoxy.Model
		defaults:
			companyId: 0
			hasCompanies: undefined
			userImage: ''

			unread_amount: 0

			company_name: ''
			company_image_url: ''
			company_is_active: 0
			legal_name: '...'
			addresses_count: '0 адресов'
			deposit_amount: '0.00 рублей'

			allCompaniesHref: '/office'
			allCompaniesText: 'Все компании'
			myCompanyIds: []
			myCompaniesLoaded: false

	class Views.Layout extends Marionette.LayoutView
		className: 'iconto-layout iconto-office-layout green'
		template: JST['office/templates/layout']

		behaviors:
			Epoxy: {}
			Subscribe: {}

		ui:
			offCanvasWrap: '.off-canvas-wrap'
			profile: '[name=profile]'
			companies: '[name=companies]'
			money: '[name=money]'
			customers: '[name=customers]'
			partners: '[name=partners]'
			messages: '[name=messages]'
			offers: '[name=offers]'
			shop: '[name=shop]'
			analytics: '[name=analytics]'
			branding: '[name=branding]'
			spots: '[name=spots]'
			documents: '[name=documents]'
			terms: '[name=terms]'
			addTransaction: '[name=add-transaction]'
			userProfile: '.off-canvas-list [name=user-profile] a'
			companyInfo: '#company-info'

		bindings:
			'.header .avatar': "attr: { src:resize(get(user_image, 'url'), Iconto.shared.helpers.image.FORMAT_SQUARE_SMALL) }"
			'.header .user-name': "text:format('$1 $2', user_first_name, user_last_name)"

			'[name=companies]': 'toggle: not(viewModel_companyId)'
			'[name=selected-info]': 'toggle: viewModel_companyId'

			'.menu [name=profile]': "toggle: viewModel_companyId"
			'.menu [name=profile] a': "attr: { href: format('/office/$1/profile', state_companyId) }"

			'[name=money]': "toggle: all(viewModel_companyId, viewModel_company_is_active)"
			'[name=money] a': "attr: { href: format('/office/$1/money', state_companyId) }"

			'[name=customers]': "toggle: all(viewModel_companyId, viewModel_company_is_active)"
			'[name=customers] a': "attr: { href: format('/office/$1/customers', state_companyId) }"

			'[name=partners]': "toggle: all(viewModel_companyId, viewModel_company_is_active)"
			'[name=partners] a': "attr: { href: format('/office/$1/partners', state_companyId) }"

			'[name=messages]': "toggle: all(viewModel_companyId, viewModel_company_is_active, state_companyId), classes: { 'show-notification': unread_amount }"
			'[name=messages] a': "attr: { href: format('/office/$1/messages', state_companyId) }"

			'[name=offers]': "toggle: all(viewModel_companyId, viewModel_company_is_active)"
			'[name=offers] a': "attr: { href: format('/office/$1/offers', state_companyId) }"

			'[name=analytics]': "toggle: all(viewModel_companyId, viewModel_company_is_active)"
			'[name=analytics] a': "attr: { href: format('/office/$1/analytics/operations', state_companyId) }"

			'[name=branding]': "toggle: all(viewModel_companyId, viewModel_company_is_active)"
			'[name=branding] a': "attr: { href: format('/office/$1/branding', state_companyId) }"

			'[name=spots]': "toggle: all(viewModel_companyId, viewModel_company_is_active)"
			'[name=spots] a': "attr: { href: format('/office/$1/spots', state_companyId) }"

			'[name=documents]': "toggle: all(viewModel_companyId, viewModel_company_is_active)"
			'[name=documents] a': "attr: { href: format('/office/$1/documents', state_companyId) }"

			'[name=shop]': "toggle: all(viewModel_companyId, viewModel_company_is_active)"
			'[name=shop] a': "attr: { href: format('/office/$1/shop', state_companyId) }"

			'[name=add-transaction]': "toggle: all(viewModel_companyId, viewModel_company_is_active)"
			'[name=add-transaction] a': "attr: { href: format('/office/$1/add-transaction', state_companyId) }"

#			'[name=analytics]': "toggle: all(viewModel_companyId, viewModel_company_is_active)"
#			'[name=analytics] a': "attr: { href: format('/office/$1/analytics', state_companyId) }"

			'[name=terms] a': "attr: { href: '/office/terms' }"
			'[name=wallet] a': "attr: { href: '/wallet' }"
			'[name=user-profile]': "attr: { href: '/office/profile' }"

			'[name=all-companies]': "classes: { hide: not(viewModel_companyId) }"
			'[name=all-companies] a': "attr: { href: viewModel_allCompaniesHref }"
			'[name=all-companies] .content': "text: viewModel_allCompaniesText"

			'.all-companies': "attr: { href: viewModel_allCompaniesHref }, classes: { hide: not(viewModel_companyId) }"
			'.all-companies span': "text: viewModel_allCompaniesText"

			'#company-image': "attr: { src:viewModel_company_image_url}"
			'#company-name': "text: viewModel_company_name"
			'.company-legal': 'text: viewModel_legal_name'
			'.company-addresses': 'text: viewModel_addresses_count'
			'.company-deposit': 'text: viewModel_deposit_amount'

			'.user-profile-messages': 'toggle: unread_amount'
			'.user-profile-messages-count': 'text: unread_amount'
			'.user-profile-messages-text span': "text: declension(unread_amount, ['диалог', 'диалога', 'диалогов'])"

			'.user-profile .user-profile-image img': "attr: { src:viewModel_userImage }"
			'.user-profile .user-profile-name': 'text: format("$1 $2", user_first_name, user_last_name)'

		events:
			'click .menu a, .user-profile a': 'onOffCanvasLinkClick'
			'click [name=office-logout]': 'officeLogout'

		bindingSources: ->
			viewModel: @viewModel
			state: @state
			user: @user

		initialize: =>
			@viewModel = new LayoutViewModel()
			@user = new Iconto.REST.User()

			@state = new Iconto.office.models.StateViewModel @options
			@state.on 'change', @update

			Iconto.commands.setHandler 'user:image:change', (url) =>
				@user.set image:
					url: url

		onRender: =>
			$('body').addClass('office')
			@addRegions
#				mainRegion: '#main-region'
				mainRegion: new Iconto.shared.views.updatableregion.UpdatableRegion(el: '#main-region')
				slideableRegionLeft: new Iconto.shared.views.updatableregion.UpdatableRegion(el: '#slideable-region-left', animate:true)
				slideableRegionRight: new Iconto.shared.views.updatableregion.UpdatableRegion(el: '#slideable-region-right', animate:true)
				slideableRegionRight2: new Iconto.shared.views.updatableregion.UpdatableRegion(el: '#slideable-region-right2', animate:true)

			@listenTo Iconto.events, 'message:read', @onGlobalMessageRead

			@update()
			.then =>
				if @options.companyId
					Iconto.commands.setHandler 'company:update', (company) =>
						@viewModel.set company_image_url: Iconto.shared.helpers.image.resize(company.image.url,
								Iconto.shared.helpers.image.FORMAT_SQUARE_SMALL)

			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		update: =>
			@updateLinks()

			state = @state.toJSON()

			reason =
				type: Iconto.REST.Reason.TYPE_COMPANY_AGGREGATED
				company_id: state.companyId

			@loadData(state)
			.then =>
				ViewClass = Views.factory(state)

				region = @getRegion(state)
				if region
					if state.forceShow
						region.show new ViewClass(state)
					else
						region.showOrUpdate ViewClass, state
				else
					console.error 'region not found is not defined'

				true
			.catch (error) =>
				console.error error
				if error.status is 200002
					error.msg = "Доступ запрещен"
					Iconto.shared.views.modals.ErrorAlert.show _.extend error,
						onCancel: ->
							Iconto.office.router.navigate "office", trigger: true
				else
					throw error

		updateLinks: =>
			@$('aside .menu div').removeClass('active')
			switch @state.get('page')
				when 'index'
					@ui.companies.addClass 'active'
				when 'company-profile', 'legal', 'addresses', 'employees', 'edit'
					@ui.profile.addClass 'active'
				when 'money', 'deposit'
					@ui.money.addClass 'active'
				when 'customers'
					@ui.customers.addClass 'active'
				when 'partners'
					@ui.partners.addClass 'active'
				when 'messages'
					@ui.messages.addClass 'active'
				when 'offers'
					@ui.offers.addClass 'active'
				when 'analytics'
					@ui.analytics.addClass 'active'
				when 'branding'
					@ui.branding.addClass 'active'
				when 'spots'
					@ui.spots.addClass 'active'
				when 'documents'
					@ui.documents.addClass 'active'
				when 'user-profile'
					@ui.userProfile.addClass 'active'
				when 'shop'
					@ui.shop.addClass 'active'
				when 'add-transaction'
					@ui.addTransaction.addClass 'active'

		loadData: (state) =>
			Iconto.api.auth()
			.then (user) =>
#				Iconto.commands.execute 'workspace:authorised'
				@user.set user
				@viewModel.set userImage: Iconto.shared.helpers.image.resize(user.image.url,
						Iconto.shared.helpers.image.FORMAT_SQUARE_LARGE)

				if state.companyId
					Iconto.notificator.setFilter 'data.companyId',
						value: state.companyId

				if user.id
					Iconto.notificator.setFilter 'data.userId',
						value: user.id

			.then =>
				Q.fcall =>
					unless @viewModel.get('myCompaniesLoaded')
						(new Iconto.REST.CompanyCollection()).fetchIds(filters: ['my'])
						.then (companyIds) =>
#							companyIds = [3116]
							if companyIds.length is 1
								@viewModel.set
									allCompaniesHref: '/office/new'
									allCompaniesText: 'Добавить компанию'
									myCompanyIds: companyIds
									myCompaniesLoaded: true
			.then =>
				Q.fcall =>
					if state.companyId

						getCompanyIds = (roles) ->
							# get all user companies from user.roles
							companyIds = []
							_.each roles, (role) ->
								companyIds.push +role.param.company if role.param.company
							companyIds

						#TODO: change to WS
						#						unless _.contains getCompanyIds(user.roles), state.companyId
						# update user roles to check if new companies are available
						@user.fetch(null, reload: true)
						.then (_user) =>
							unless _.contains getCompanyIds(_user.roles), state.companyId
								# no such privileges even after reload
								@mainRegion?.reset()
								throw status: 200002
				.then (user) =>
					state.user = @user.toJSON()

					#unsubscribe from previous
					unsubscribes = []
					if @companySubscription
						#unsubscribe only if company has changed
						unless @companySubscription.companyId is state.companyId
							unsubscribeCompanySubscription = Iconto.ws.unsubscribe(@companySubscription.route)
							.then =>
								console.warn 'delete @companySubscription'
								delete @companySubscription
							unsubscribes.push unsubscribeCompanySubscription

					if @companyMessageSubscription
						#unsubscribe only if company has changed
						unless @companyMessageSubscription.companyId is state.companyId
							unsubscribeCompanyMessageSubscription = Iconto.ws.unsubscribe(@companyMessageSubscription.route)
							.then =>
								console.warn 'delete @companyMessageSubscription'
								delete @companyMessageSubscription
							unsubscribes.push unsubscribeCompanyMessageSubscription

					Q.all unsubscribes

				.then =>
					@viewModel.set companyId: if state.companyId then state.companyId else 0
					return unless state.companyId
					#subscribe

					if not @companySubscription or not @companyMessageSubscription
						if _.get Iconto, 'ws.connection.socket.connected'
							@subscribeRequired state
						else
							@listenTo Iconto.ws, 'connected', @subscribeRequired.bind @, state

					# count company addresses
					(new Iconto.REST.AddressCollection()).count(company_id: state.companyId)
					.then (amount) =>
						@viewModel.set addresses_count: amount + ' ' + Iconto.shared.helpers.declension(amount,
								['адрес', 'адреса', 'адресов'])
					.dispatch(@)
					.catch (error) =>
						console.error error
						Iconto.shared.views.modals.ErrorAlert.show error
					.done()

					# fetch company
					(new Iconto.REST.Company(id: state.companyId)).fetch()
					.then (company) =>
						state.company = _.defaults company, Iconto.REST.Company::defaults
						@viewModel.set
							company_name: company.name
							company_image_url: Iconto.shared.helpers.image.resize(company.image.url,
									Iconto.shared.helpers.image.FORMAT_SQUARE_SMALL)
							company_is_active: company.is_active

						# fetch legal
						if company.legal_id
							(new Iconto.REST.LegalEntity(id: company.legal_id)).fetch()
							.then (legal) =>
								@viewModel.set legal_name: Iconto.shared.helpers.legal.getLegal legal
								state.legal = legal

								#load deposit async
								(new Iconto.REST.Deposit(id: legal.deposit_id)).fetch({}, reload: true)
								.then (deposit) =>
									_.set state, 'legal.deposit_amount', parseFloat deposit.amount
									@viewModel.set deposit_amount: Iconto.shared.helpers.money(deposit.amount) + ' ' +
											Iconto.shared.helpers.declension(Math.floor(deposit.amount),
													['рубль', 'рубля', 'рублей'])
								.dispatch(@)
#									.catch (error) =>
#										console.error error
#										Iconto.shared.views.modals.ErrorAlert.show error
							.catch (err) =>
								console.error err
								@viewModel.set
									deposit_amount: '0.00 рублей'
									legal_name: ''
								state.legal = (new Iconto.REST.LegalEntity()).toJSON()

						else
							@viewModel.set
								deposit_amount: '0.00 рублей'
								legal_name: ''
							state.legal = (new Iconto.REST.LegalEntity()).toJSON()
			.catch (error) =>
				console.error error
#				Iconto.commands.execute 'workspace:unauthorised'

				# propagate error to loadData method
				throw error

		subscribeRequired: (state) =>
			reason =
				type: Iconto.REST.Reason.TYPE_COMPANY_AGGREGATED
				company_id: state.companyId

			wsSubscriptions = [
				Iconto.ws.subscribe('EVENT_GROUP_UPDATE', reasons: [reason], @onGroupUpdate)
				Iconto.ws.subscribe('EVENT_MESSAGE_CREATE', reasons: [reason], @onMessageCreate )
			]

			Q.all wsSubscriptions
			.then ([eventGroupUpdateRes, eventMessageCreateRes]) =>
				# EVENT_GROUP_UPDATE
				@companySubscription = state.companySubscription =
					companyId: state.companyId
					route: eventGroupUpdateRes.route

				# EVENT_MESSAGE_CREATE
				@companyMessageSubscription = state.companyMessageSubscription =
					companyId: state.companyId
					route: eventMessageCreateRes.route

			.catch (error) =>
				console.error error
				alertify.error 'websockets error'
			.done()

			if state.companyId
				(new Iconto.REST.GroupCollection()).fetchAll({reasons: [reason]})
				.then (groups) =>
					aux = (acc, group) ->
						acc + group.unread_amount
					unreadAmount = _.reduce groups, aux, 0
					@viewModel.set 'unread_amount', unreadAmount
			else
				@viewModel.set 'unread_amount', 0

		onOffCanvasLinkClick: (e) =>
			@ui.offCanvasWrap.removeClass 'move-right'

		onShow: =>
			$(document).foundation()

		onMessageCreate: (data) =>
			Iconto.ws.trigger 'message:received', data

			currentUnreadAmount = @viewModel.get 'unread_amount'
			@viewModel.set 'unread_amount', currentUnreadAmount + 1

			roomViewId = _.get data, 'room_view.id'
			companyId = @state.get 'companyId'

			messageType = _.get data, 'message.type'
			systemMessage = messageType is Iconto.REST.Message.PRODUCER_TYPE_SYSTEM

			attachments = _.get(data, 'message.attachments', [])
			messageBody = if attachments.length > 0
				attachmentType = _.get(data,'message.attachments[0].type')
				attachmentTypeString = Iconto.REST.Attachment.getTypeString attachmentType
				"#{attachmentTypeString}"
			else
				_.get data, 'message.body'

			notificationData =
				companyId: if systemMessage then null else _.get data, 'message.company_id'
				userId: _.get data, 'message.user_id'

			defer = =>
				Iconto.notificator.notify
					body:	messageBody
					title:	_.get data, 'room_view.name'
					icon:	_.get data, 'room_view.image.url'
					tag: 	roomViewId
					timeout: 7
					data: notificationData
					onClick: =>
						# dirty hack to force page reload when redirecting from one chat to another4
						intermediateRoute = "/office/#{companyId}/messages/chats"
						route = "/office/#{companyId}/messages/chat/#{roomViewId}"
						Iconto.shared.router.navigate intermediateRoute, trigger: true
						Iconto.shared.router.navigate route, trigger: true
			setTimeout defer, 100

		onGlobalMessageRead: (sequenceNumber, roomView) =>
			currentUnreadAmount = @viewModel.get 'unread_amount'
			@viewModel.set 'unread_amount', if currentUnreadAmount <= 0 then 0 else currentUnreadAmount - 1

		onGroupUpdate: (data) =>
			if data.type is Iconto.REST.Group.UPDATE_TYPE_UNREADAMOUNT
				@viewModel.set 'unread_amount', data.group.unread_amount

		onRoomViewUpdate: (msg) =>

		getRegion: (state) =>
			viewClassName = Views.factory(state).name

			switch _.get state, 'updateOptions.position'
				when 'right'
					console.info "Showing #{viewClassName} view in RIGHT region"
					@slideableRegionRight.empty()
					@slideableRegionRight
				when 'right2'
					console.info "Showing #{viewClassName} view in RIGHT2 region"
					@slideableRegionRight2.empty()
					@slideableRegionRight2
				when 'left'
					console.info "Showing #{viewClassName} view in LEFT region"
					@slideableRegionLeft.empty()
					@slideableRegionLeft
				else
					console.info "Showing #{viewClassName} view in MAIN region"
					if @slideableRegionRight?.isVisible()
						@slideableRegionRight.hide()
					if @slideableRegionRight2?.isVisible()
						@slideableRegionRight2.hide()
					if @slideableRegionLeft?.isVisible()
						@slideableRegionLeft.hide()

					@mainRegion

		onBeforeDestroy: =>
			$('body').removeClass('office')
			Iconto.notificator.unsetFilter 'data.companyId'
			Iconto.notificator.unsetFilter 'data.userId'
			if @companySubscription
				Iconto.ws.unsubscribe(@companySubscription.route)
			if @companyMessageSubscription
				Iconto.ws.unsubscribe(@companyMessageSubscription.route)
