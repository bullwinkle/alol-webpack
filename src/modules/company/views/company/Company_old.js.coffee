@Iconto.module 'company.views', (Views) ->
	class CompanyView extends Marionette.LayoutView
		className: 'company-view mobile-layout'
		template: JST['company/templates/company/company']

		behaviors:
			Epoxy: {}
			Layout: {}

		ui:
			tab: '.tab'
			goToShopButton: '[name=go-to-shop-button]'

		events:
			'click [name=send-message-to-company]': 'onSendMessageToCompanyClick'
			'click @ui.goToShopButton': 'onGoToShopButtonClick'

		regions:
			viewRegion: '#view-region'

		initialize: ->
			@model = new Iconto.REST.Company id: @options.companyId, site_url: ''
			@state = new Iconto.company.models.StateViewModel _.extend @options,
				categoryName: ''
				addresses: []

			@listenTo @state, 'change:action', @update
		onRender: =>
			@update()

			@model.fetch(null, {reload: true})
			.then (model) =>
				model.image_url = @model.get('image').url
				@model.set model

				(new Iconto.REST.CompanyCategory(id: model.category_id)).fetch()
			.then (category) =>
				@state.set
					isLoading: false
					categoryName: category.name
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error

		onBeforeDestroy: =>
			Iconto.commands.execute 'workspace:clearDefaultCompanyStyles'

		onShow: =>
			companyId = @state.get('companyId') or @state.get('company_id')
			company = Iconto.REST.Company.checkCompanyIfMain companyId
			if company
				Iconto.commands.execute 'workspace:setCustomCompanyStyles', company
			else
				Iconto.commands.execute 'workspace:clearDefaultCompanyStyles'

		update: =>
			@ui.tab.removeClass('active')
			@$('.tab-' + @state.get('action')).addClass('active')

			# invoke respective function
			@[@state.get('action')]?()

		openChat: (userId=@options.user.id, addressId=null, companyId=@options.companyId) =>
			return false if @onWriteButtonClickLock
			@onWriteButtonClickLock = true

			roomView = new Iconto.REST.RoomView()

			reasons = []
			reasons.push {type: Iconto.REST.Reason.TYPE_USER, user_id: userId}
			if addressId
				reasons.push {type: Iconto.REST.Reason.TYPE_ADDRESS, address_id: addressId}
			else if companyId
				reasons.push {type: Iconto.REST.Reason.TYPE_COMPANY, company_id: companyId}
			else
				return false

			roomView.save(reasons: reasons)
			.then (response) =>
				Iconto.wallet.router.navigate "wallet/messages/chat/#{response.id}", trigger: true
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@onWriteButtonClickLock = false

		onSendMessageToCompanyClick: =>
			Iconto.api.auth()
			.then (user) =>
				if user and user.id and @options.companyId
					@openChat user.id, null, @options.companyId
			.catch =>
				Iconto.shared.views.modals.PromptAuth.show preset: 'soft'

		onGoToShopButtonClick: =>
#			if !@options.user or !@options.user.id or !@options.user.phone
##				return Iconto.shared.router.navigate '/auth', trigger: true
#				return Iconto.shared.views.modals.PromptAuth.show preset: 'soft'

			user = @options.user or {}
			userId = user.id or 0
			userPhone = user.phone or null

			company = @model.toJSON()
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

		info: =>
			@viewRegion.show new Iconto.company.views.CompanyInfoView @options

		offers: =>
#			@viewRegion.show new Iconto.company.views.CompanyOffersView @options
			@viewRegion.show new Iconto.company.views.offers.FeedBaseView @options

		news: =>
			@viewRegion.show new Iconto.company.views.CompanyNewsView @options