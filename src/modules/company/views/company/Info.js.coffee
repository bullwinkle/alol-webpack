@Iconto.module 'company.views', (Views) ->
	class Views.CompanyInfoView extends Marionette.ItemView
		className: 'company-info-view'
		template: JST['company/templates/company/info']

		behaviors:
			Epoxy: {}

		ui:
			addressesShowMoreButton: '.addresses-show-more-button'
			photosShowMoreButton: '.photos-show-more-button'
			photo: '.photo-image'

		events:
			'click [data-address-id]' : 'onWriteToButtonClick'
			'click [data-phone]' : 'onPhoneCallButtonClick'
			'click [data-coords]' : 'onShowMapButtonClick'
			'click @ui.addressesShowMoreButton': 'onAddressesShowMoreButtonClick'
			'click @ui.photosShowMoreButton': 'onPhotosShowMoreButtonClick'
			'click @ui.photo': 'onPhotoClick'

		bindings:
			".info": "toggle: not(state_isLoadingInfo)"
			".list-addresses": "toggle: length(state_addresses)"
			".addresses-inline-badge": "text: length(state_addresses)"
			".addresses": "underscore: state_addresses"
			".list-site": "toggle: site"
			".link": "attr: { href: site }, text: site"
			".list-description": "toggle: description"
			".list-description .text": "html: description"
			".list-photos": "toggle: length(state_photos)"
			".photos-inline-badge": "text: length(state_photos)"
			".addresses-show-more-button": "toggle: gt(length(state_addresses), 5)"
			".photos-show-more-button": "toggle: gt(length(state_photos), 6)"
			".photos": "underscore: state_photos"
			".info-content": "toggle: not(state_isLoadingInfo)"
			".loader-bubbles": "toggle: state_isLoadingInfo"

		initialize: ->
			@model = new Iconto.REST.Company id: @options.companyId, site_url: ''
			@state = new Iconto.company.models.StateViewModel _.extend @options,
				addresses: []
				photos: []
				isLoadingInfo: true

		onRender: =>
			modelPromise = @model.fetch(null, {reload: true})
			.then (model) =>
				model.site_url = Iconto.shared.helpers.navigation.parseUri(model.site).origin
				@model.set model
				(new Iconto.REST.CompanyCategory(id: @model.category_id)).fetch()
			.then (category) =>
				@state.set categoryName: category.name
			.dispatch(@)
			.catch (error) ->
				console.log error

			addressesPromise = (new Iconto.REST.AddressCollection()).fetchAll(company_id: @model.get('id'))
			.then (addresses) =>
				@state.set addresses: addresses
			.dispatch(@)
			.catch (error) ->
				console.log error

			socialContentPhotoPromise = (new Iconto.REST.SocialContentCollection()).fetch(company_id: @options.companyId, type: 'photos', from: 'fb')
			.then (photos) =>
				@state.set photos: photos
			.dispatch(@)
			.catch (error) ->
				console.error error

			Promise.settle([modelPromise, addressesPromise, socialContentPhotoPromise])
			.then =>
				@state.set isLoadingInfo: false
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error

		openChat: (userId, addressId, companyId) =>
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

		onWriteToButtonClick: (e) =>
			data = $(e.currentTarget).data()
			return false unless data.addressId

			Iconto.api.auth()
			.then (user) =>
				@openChat user.id, data.addressId
			.catch =>
				Iconto.shared.views.modals.PromptAuth.show
					preset: 'soft'
					successCallback: @onWriteToButtonClick.bind @, e

		onShowMapButtonClick: (e) =>
			data = $(e.currentTarget).data()
			return false unless data.coords

			window.open Url.format
				hostname: 'google.com'
				protocol: 'https'
				pathname: 'maps/place'
				query:
					q: @model.get('name')	# query
					ll: data.coords			# coords
					z: 15					# zoom

		onPhoneCallButtonClick: (e) =>
			data = $(e.currentTarget).data()
			return false unless data.phone

			window.location.assign "tel:+#{data.phone}"

		onAddressesShowMoreButtonClick: =>
			if @ui.addressesShowMoreButton.text() is 'Показать все'
				@ui.addressesShowMoreButton.text 'Скрыть'
			else
				@ui.addressesShowMoreButton.text 'Показать все'
			@$('.address.hidden').toggleClass('hide')

		onPhotosShowMoreButtonClick: =>
			if @ui.photosShowMoreButton.text() is 'Показать еще'
				@ui.photosShowMoreButton.text 'Скрыть'
			else
				@ui.photosShowMoreButton.text 'Показать еще'
			@$('.photo.hidden').toggleClass('hide')

		onPhotoClick: (e) =>
			src = $(e.currentTarget).data('url')
			Iconto.shared.views.modals.LightBox.show
				img: src