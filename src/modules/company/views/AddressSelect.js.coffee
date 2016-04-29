@Iconto.module 'company.views', (Views) ->

	class Views.AddressItemView extends Marionette.ItemView
		tagName: 'a'
		className: 'button list-item menu-item address-item-view'
		template: JST['company/templates/address-item']
		events:
			'click': 'onClick'
		attributes: =>
			href: "/wallet/company/#{@model.get('company_id')}/address/#{@model.get('id')}"
		onClick: (e) =>
			@trigger 'click', e

	class Views.AddressSelectView extends Marionette.CompositeView
		className: 'address-select-view mobile-layout'
		template: JST['company/templates/address-select']
		childView: Views.AddressItemView
		childViewContainer: '.list'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
			OrderedCollection: {}

		ui:
			topbarLeftButton: '.topbar-region .left-small'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'

		bindingSources: =>
			company: @company
			category: @category

		initialize: =>
			@state = new Iconto.company.models.StateViewModel @options
			@state.set
				topbarTitle: 'Адреса компании'

			if not Iconto.shared.router.isRoot
				@state.set
					topbarLeftButtonClass: ''
					topbarLeftButtonSpanClass: 'ic-chevron-left'

			@company = new Iconto.REST.Company id: @options.companyId
			@category = new Iconto.REST.CompanyCategory()
			@collection = new Iconto.REST.AddressCollection()

		onRender: =>
			@company.fetch()
			.then (company) =>
				@category.set id: company.category_id
				@category.fetch() if company.category_id

			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()
			@collection.fetchAll(company_id: @options.companyId)
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set isLoading: false

		onTopbarLeftButtonClick: =>
			Iconto.shared.router.navigateBack()

		onChildviewClick: (view, e) =>
			console.log arguments
			if @options.chatStraightway
				e.preventDefault()
				e.stopPropagation()
				addressId = view.model.get('id')
				userId = @options.user.id
				@openChat userId, addressId

		openChat: (userId, addressId) =>
			return false if @onWriteButtonClickLock
			@onWriteButtonClickLock = true
#			@ui.writeButton.addClass 'is-loading'
			roomView = new Iconto.REST.RoomView()

			reasons = []
			reasons.push {type: Iconto.REST.Reason.TYPE_USER, user_id: userId }
			reasons.push {type: Iconto.REST.Reason.TYPE_ADDRESS, address_id: addressId }

			roomView.save(reasons: reasons)
			.then (response) =>
				Iconto.wallet.router.navigate "wallet/messages/chat/#{response.id}", trigger: true
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@onWriteButtonClickLock = false
#				@ui.writeButton.removeClass 'is-loading'


