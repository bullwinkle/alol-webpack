@Iconto.module 'wallet.views.messages', (Messages) ->
	class Messages.ChatView extends Iconto.chat.views.ChatView
		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
				outlets:
					topbar: JST['wallet/templates/messages/chats/topbar']
			OrderedCollection: {}
			Subscribe:
				'EVENT_MESSAGE_READ':
					args: ->
						room_view_ids: [@roomView.get('id')]
						reasons: [
							{type: Iconto.REST.Reason.TYPE_USER, user_id: _.get(@options, 'user.id')}
						]
					handler: 'onMessageRead'

		ui: #extends prototype's ui
			topbarLeftButton: '.topbar-region .left-small'
		#			infoButton: '.topbar-region .logo'
			topbarRightButton: '.topbar-region .right-small'
			callButton: '.topbar-region [name=phone-call]'
			blockButton: '.topbar-region [name=block]'
			actions: '.topbar-region .actions'
			orderButton: '.order-button'
			overlay: '.overlay'
			goToCompanyReviewChat: '.go-to-company-review-chat'

		events: #extends prototype's events
		#			'click @ui.infoButton': 'onInfoButtonClick'
			'click .topbar-region .disabled': 'onDisabledButtonClick'
			'click @ui.blockButton': 'onBlockButtonClick'
			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'
			'click @ui.orderButton': 'onOrderButtonClick'
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
		#			'click @ui.topbarHeader': 'onTopbarHeaderClick'
		#			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'
			'click @ui.goToCompanyReviewChat': 'onGoToCompanyReviewChatClick'

		constructor: ->
			@ui = _.extend @ui, Iconto.chat.views.ChatView::ui
			@events = _.extend @events, Iconto.chat.views.ChatView::events
			super

		initialize: =>
			super()

			@state = new Iconto.wallet.models.StateViewModel _.extend {}, @options,
				is_new_company: false
				limit: 10
				offset: 0
				headerLink: ''
				company: null
				topbarLeftButtonClass: ''
				topbarLeftButtonSpanClass: 'ic-chevron-left'
				topbarRightButtonClass: 'is-visible'

			@user = new Iconto.REST.User @options.user
			@roomView = new Iconto.REST.RoomView id: @options.chatId
			@collection = new Iconto.REST.MessageCollection()

			@on 'render', =>
				$('html').on "click.actions.#{@cid}", (e) =>
					@ui.actions.removeClass 'open'
			@on 'before:destroy', =>
				$('html').off "click.actions.#{@cid}"

			@listenTo Iconto.ws, 'message:received', (data) =>
				@onMessageCreate data

		fetchRoom: ->
			super()
			.then (roomView) =>
				@state.set topbarTitle: roomView.name

				# Get groups, because only in group with ROLE_MERCHANT
				# you can find reasons with review_id, address_id, company_id etc.
				(new Iconto.REST.GroupCollection().fetchAll(room_id: @roomView.get('room_id')))
			.then (groups) =>
				# promises from reason
				promises = []

				# find group with ROLE_MERCHANT
				group = _.find groups, (g) ->
					g.role is Iconto.REST.Group.ROLE_MERCHANT

				if group
					if reviewId = _.get group, 'reason.review_id'
						@state.set reviewId: reviewId
						@reviewPromise = (new Iconto.REST.CompanyReview(id: reviewId)).fetch()
						promises.push @reviewPromise
					if companyId = _.get group, 'reason.company_id'
						@state.set companyId: companyId
						@companyPromise = (new Iconto.REST.Company(id: companyId)).fetch()
						promises.push @companyPromise
					if addressId = _.get group, 'reason.address_id'
						@state.set addressId: addressId
						@addressPromise = (new Iconto.REST.Address(id: group.reason.address_id)).fetch()
						promises.push @addressPromise

					Reason = Iconto.REST.Reason
					if group.reason.type in [Reason.TYPE_COMPANY_AGGREGATED, Reason.TYPE_COMPANY, Reason.TYPE_ADDRESS]
						@state.set headerLink: "wallet/company/#{group.reason.company_id}"
				Q.settle(promises)
			.then ([company, address])  =>
				if @reviewPromise and @reviewPromise.value()
					@state.set isRatedReview: @reviewPromise.value().rating isnt Iconto.REST.CompanyReview.RATING_NONE

				if _.result company, 'isFulfilled'
					company = company.value()
					@state.set
						company: company
						topbarRightLogoIcon: ICONTO_COMPANY_CATEGORY[company.category_id]

				if _.result address, 'isFulfilled'
					@state.set 'address', address.value()

				@state.toJSON()

		onTopbarLeftButtonClick: =>
			defaultRoute = '/wallet/messages/chats'
			parsedUrl = Iconto.shared.helpers.navigation.parseUri()
			fromRoute = _.get parsedUrl, 'query.from'
			route = fromRoute or defaultRoute
			Iconto.shared.router.navigate route, trigger: true

		onTopbarRightButtonClick: (e) =>
			link = @state.get 'headerLink'
			Iconto.wallet.router.navigate link, trigger: true if link
		#			link = @state.get 'headerLink'
		#			Iconto.wallet.router.navigate link, trigger: true if link

		#		onTopbarHeaderClick: =>
		#			link = @state.get 'headerLink'
		#			Iconto.wallet.router.navigate link, trigger: true if link

		#		onInfoButtonClick: =>
		#			link = @state.get 'headerLink'
		#			Iconto.wallet.router.navigate link, trigger: true if link

		onDisabledButtonClick: (e) =>
			e.preventDefault()
			return false

		onBlockButtonClick: =>
			@ui.blockButton.attr 'disabled', true
			Iconto.shared.views.modals.Confirm.show
				title: 'Блокировка чата'
				message: 'Вы уверены, что хотите заблокировать чат?'
				onSubmit: =>
					@roomView.setBlocked(true)
					.then =>
						Iconto.wallet.router.navigate "/wallet/messages/chats", trigger: true
					.dispatch(@)
					.catch (error) =>
						console.error error
						if error.status is 'access_denied'
							error.msg = 'Вы не можете заблокировать этот чат'
						Iconto.shared.views.modals.ErrorAlert.show error
					.done =>
						@ui.blockButton.removeAttr 'disabled'
				onCancel: =>
					@ui.blockButton.removeAttr 'disabled'

		renderSubmitForm: (state = {}) =>
			rendered = _.get @, 'chatSubmitView.isRendered'
			return false if rendered

			@chatSubmitView = new Messages.SubmitView _.extend state, @options, room_id: @roomView.get('room_id')
			@chatSubmitView.render()
			@listenTo @chatSubmitView,
				'add-message-request': (message) => @sendMessage message
				'faq:change:visible': (faqVisible, faqState) =>
					@ui.overlay["#{if faqVisible then 'add' else 'remove'}Class"] 'is-visible'
					setTimeout =>
						@ui.messages.scrollToBottom()
					, 250
					@ui.overlay.one 'click', =>
						@chatSubmitView.trigger 'faq:hide'

			appendChatSubmitView = =>
				try
					@ui.formSubmitRegion.append @chatSubmitView.$el
					return true
				catch err
					console.warn 'couldn`t renderSubmitForm:', err
					return false
			unless appendChatSubmitView()
				setTimeout appendChatSubmitView, 500

		onOrderButtonClick: =>
			user = @state.get('user')
			userId = user.id
			userPhone = user.phone

			company = @state.get('company')
			companyId = company.id or 0
			companyOrderType = company.order_form_type
			externalOrderFormUrl = company.order_form_url

			addressId = @state.get('addressId') or 0

			switch companyOrderType
				when Iconto.REST.Company.SHOP_STATUS_ENABLED_EXTERNAL
				# hook for opening TAXI ORDER FORM in current tab
					if company?.id is Iconto.REST.Company.mapDomainToCompanyIds Iconto.REST.Company.MAIN_COMPANY_IDS.taxi
						# open taxi form in current browser tab
						externalOrderFormUrl = "#{Iconto.REST.Company.TAXI_FORM_PATH}?phone=#{userPhone}&user_id=#{userId}&company_id=#{companyId}"
						#						openInNewPage = false
						Iconto.shared.router.navigate externalOrderFormUrl, trigger: true
					else
						# open external url in new browser tab
						externalOrderFormUrl = Iconto.shared.helpers.navigation.parseUri(externalOrderFormUrl).href
						newTab = window.open externalOrderFormUrl, '_blank'
						newTab.focus()

				when Iconto.REST.Company.SHOP_STATUS_ENABLED_INTERNAL
					route = "/wallet/company/#{companyId}#{if addressId then "/address/#{addressId}" else ''}/shop?navigateBack=#{Backbone.history.fragment}"
					Iconto.shared.router.navigate route, trigger: true
#
#			if externalOrderFormUrl
#				# hack for opening TAXI ORDER FORM
#				if company?.id is Iconto.REST.Company.mapDomainToCompanyIds Iconto.REST.Company.MAIN_COMPANY_IDS.taxi
#					externalOrderFormUrl = "/wallet/services/taxi?phone=#{userPhone}&user_id=#{userId}&company_id=#{companyId}"
#					openInNewPage = false
#				else
#					openInNewPage = true
#
#			if externalOrderFormUrl
#				if openInNewPage
#					externalOrderFormUrl = Iconto.shared.helpers.navigation.parseUri(externalOrderFormUrl).href
#					newTab = window.open externalOrderFormUrl, '_blank'
#					newTab.focus()
#				else
#					Iconto.shared.router.navigate externalOrderFormUrl, trigger: true
#			else
#				route = "/wallet/company/#{companyId}#{if addressId then "/address/#{addressId}" else ''}/shop?navigateBack=#{Backbone.history.fragment}"
#				Iconto.shared.router.navigate route, trigger: true

