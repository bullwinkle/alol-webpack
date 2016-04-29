@Iconto.module 'company.views', (Views) ->
	class Views.DetailsView extends Marionette.ItemView
		className: 'details-view mobile-layout'
		template: JST['company/templates/details']

		behaviors:
			Epoxy: {}
			Layout: {}
			OrderedCollection: {}

		bindingSources: =>
			company: @company
			address: @address
			category: @category

		ui:
			writeButton: '[name=write]'
			subscribeButton: '[name=subscribe]'
			blockButton: '[name=block]'
			companyImage: '.blue-header .logo'
			companyName: '.blue-header .info .company-name'
			topbarRightButton: ".topbar-region .right-small"
			topbarLeftButton: ".topbar-region .left-small"

		events:
			'click [name=write]:not(.is-loading)': 'onWriteButtonClick'
			'click [name=subscribe]:not(.is-loading)': 'onSubscribeButtonClick'
			'click [name=block]:not(.is-loading)': 'onBlockButtonClick'
			'click @ui.companyImage': 'onCompanyClick'
			'click @ui.companyName': 'onCompanyClick'
			'click @ui.topbarRightButton': "onTopbarRightButtonClick"
			'click @ui.topbarLeftButton': "onTopbarLeftButtonClick"

		initialize: =>
			@state = new Iconto.company.models.StateViewModel _.extend {}, @options,
				phone: ''
				worktime: 'Ежедневно'
				distance: 0
				company_site: ''
				topbarLeftButtonClass: ""
				topbarLeftButtonSpanClass: "ic-chevron-left"

			@company = new Iconto.REST.Company
				id: @options.companyId
			@address = new Iconto.REST.Address
				id: @options.addressId
				isSubscribed: false
				isBlocked: false
			@category = new Iconto.REST.CompanyCategory()

			@listenTo @address,
				'change:is_subscribed': (address, value) =>
					address.set 'isSubscribed', value
				'change:is_blocked': (address, value) =>
					address.set 'isBlocked', value

		onRender: =>
			companyPromise = @company.fetch()
			.then (company) =>
				@category.set id: company.category_id
				@category.fetch() if company.category_id
				company
			addressPromise = @address.fetch()
			Q.all([addressPromise, companyPromise])
			.then ([address, company]) =>
				unless address.company_id is @options.companyId
					Iconto.shared.views.modals.ErrorAlert.show
						title: 'Адресс не найден'
						message: ""
				else
					contactPhone = if address.contact_phone
						contactPhone = "+7 #{Iconto.shared.helpers.phone.format7(address.contact_phone)}"
					else ""

					site = if company.site and not company.site.match /^http[s]?:\/\//
						"http://#{company.site}"
					else company.site

					@state.set
						isLoading: false
						phone: contactPhone
						company_site: site
						topbarTitle: company.name
						topbarSubtitle: address.address
						topbarRightLogoUrl: _.get(company, 'image.url')
						topbarRightLogoIcon: ICONTO_COMPANY_CATEGORY[_.get(company, 'category_id')]
						topbarRightButtonClass: "is-visible"

			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

			Iconto.shared.services.geo.getCurrentPosition()
			.then (position) =>
				#try to update distance
				@address.fetch(lat: position.coords.latitude, lon: position.coords.longitude, {reload: true})
				.dispatch(@)
				.catch (error) =>
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()
			.catch()
			.done()

		onTopbarRightButtonClick: =>
			companyId = @state.get('companyId')
			route = "/wallet/company/#{companyId}"
			Iconto.shared.router.navigate route, trigger: true

		onTopbarLeftButtonClick: =>
			companyId = @state.get 'companyId'
			url = Iconto.shared.helpers.navigation.parseUri()
			urlQuery = url.query || {}

			triggerRoute = true
			route = switch urlQuery.from
				when "company_addresses_map"
					triggerRoute = !App.workspace.currentView.slideableRegionRight.hasView()
					"/wallet/company/#{companyId}/addresses"
				when "feed_details"
					triggerRoute = !App.workspace.currentView.slideableRegionRight.hasView()
					if urlQuery.feed and urlQuery.company
						# Iconto.shared.router.getHistory(-1)
						"/wallet/company/#{urlQuery.company}/offers/promotion/#{urlQuery.feed}"
					else
						"/wallet/company/#{companyId}/offers"
				else
					"/wallet/company/#{companyId}/addresses"
			defer = =>
				Iconto.shared.router.navigate route, trigger: triggerRoute

			@destroy()
			setTimeout defer, 10

		getRouteToBack: =>
			companyId = @state.get 'companyId'
			url = Iconto.shared.helpers.navigation.parseUri window.location.href
			urlQuery = url.query || {}
			if urlQuery.feed and urlQuery.company
				"/wallet/company/#{urlQuery.company}/offers/promotion/#{urlQuery.feed}"
			else
				"/wallet/company/#{companyId}"

		onWriteButtonClick: =>
			return false if @onWriteButtonClickLock
			@onWriteButtonClickLock = true
			@ui.writeButton.addClass 'is-loading'

			Iconto.api.auth()
			.then =>
				roomView = new Iconto.REST.RoomView()

				reasons = []
				reasons.push {type: Iconto.REST.Reason.TYPE_USER, user_id: @options.user.id}
				reasons.push {type: Iconto.REST.Reason.TYPE_ADDRESS, address_id: @options.addressId}

				roomView.save(reasons: reasons)
				.then (response) =>
					Iconto.wallet.router.navigate "wallet/messages/chat/#{response.id}", trigger: true
				.dispatch(@)
				.catch (error) =>
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
				.done =>
					@onWriteButtonClickLock = false
					@ui.writeButton.removeClass 'is-loading'
			.catch =>
				@onWriteButtonClickLock = false
				@ui.writeButton.removeClass 'is-loading'

				Iconto.commands.execute 'modals:auth:show',
					checkPreviousAuthorisedUser: false
					confirmOnClose: false


		onSubscribeButtonClick: =>
			return false if @onSubscribeButtonClickLock
			@onSubscribeButtonClickLock = true
			@ui.subscribeButton.addClass 'is-loading'

			Iconto.api.auth()
			.then =>
				method = if @address.get('is_subscribed') then 'unsubscribe' else 'subscribe'
				url = "#{(new Iconto.REST.Address()).url()}/?_method=#{method}"
				data =
					address_id: @address.get('id')

				Iconto.api.post(url, data)
				.then (response) =>
					isSubscribe = response.data.is_subscribe
					@address.set 'is_subscribed', isSubscribe
				.catch (error) =>
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
				.done =>
					@onSubscribeButtonClickLock = false
					@ui.subscribeButton.removeClass 'is-loading'
			.catch =>
				@onSubscribeButtonClickLock = false
				@ui.subscribeButton.removeClass 'is-loading'

				Iconto.commands.execute 'modals:auth:show',
					checkPreviousAuthorisedUser: false
					confirmOnClose: false


		onBlockButtonClick: =>
			return false if @onBlockButtonClickLock
			@onBlockButtonClickLock = true
			@ui.blockButton.addClass 'is-loading'

			Iconto.api.auth()
			.then =>
				method = if @address.get('is_blocked') then 'unblock' else 'block'
				url = "#{(new Iconto.REST.Address()).url()}/?_method=#{method}"
				data =
					address_id: @address.get('id')

				Iconto.api.post(url, data)
				.then (response) =>
					isBlocked = response.data.is_blocked
					@address.set 'is_blocked', isBlocked
				.catch (error) =>
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
				.done =>
					@onBlockButtonClickLock = false
					@ui.blockButton.removeClass 'is-loading'

			.catch =>
				@onBlockButtonClickLock = false
				@ui.blockButton.removeClass 'is-loading'

				Iconto.commands.execute 'modals:auth:show',
					checkPreviousAuthorisedUser: false
					confirmOnClose: false


		onCompanyClick: =>
			companyId = @company.get 'id'
			route = "/wallet/company/#{companyId}"
			Iconto.wallet.router.navigate route, trigger: true