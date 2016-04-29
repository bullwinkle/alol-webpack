@Iconto.module 'operator.views', (Views) ->
	class Views.Layout extends Marionette.LayoutView
		className: 'iconto-layout iconto-wallet-layout iconto-operator-layout fullscreen'
		template: JST['operator/templates/layout']

		behaviors:
			Epoxy: {}

		bindings:
			'.header .avatar': "attr: { src:resize(get(user_image, 'url'), Iconto.shared.helpers.image.FORMAT_SQUARE_SMALL) }"
			'[name=profile]': 'attr: { href: "/office/profile" }'
			'.user-profile .user-profile-image img': "attr: { src:resize(get(user_image, 'url')) }"
			'.user-profile .user-profile-name': "text: format('$1 $2', user_first_name, user_last_name)"
			'.user-name': 'text: user_nickname'
			'.user-image': 'attr: { src: get(user_image, "url")}, toggle: get(user_image, "id")'
			'.user-image-small': 'attr: { src: get(user_image, "url") }'

		ui:
			offCanvasWrap: '.off-canvas-wrap'

		events:
			'click .menu a, .user-profile a': 'onOffCanvasLinkClick'

		regions:
			mainRegion: '#main-region'

		bindingSources: ->
			user: @user
			viewModel: @viewModel

		initialize: ->
			@viewModel = new Iconto.operator.models.StateViewModel _.extend {}, @options

			@addRegions
				mainRegion: new Iconto.shared.views.updatableregion.UpdatableRegion(el: '#main-region')

			@state = new Iconto.operator.models.StateViewModel @options #for UpdatableRegion
			@listenTo @state, 'change:page', @update

			@user = new Iconto.REST.User()

		onRender: ->
			# initial update
			@update()

		update: ->
			state = @state.toJSON()

			ViewClass = {}

			# check auth
			Iconto.api.auth()
			.then (user) =>
				# set user
				@user.set user
				state.user = user
			.then =>
				# get view class
				ViewClass = Views.factory(state)

				# show region if no region exists
				@mainRegion.showOrUpdate ViewClass, state
			.catch (error) =>
				console.error error

		onShow: ->
			# TODO: remove foundation competely
			$(document).foundation()

		onOffCanvasLinkClick: (e) ->
			@ui.offCanvasWrap.removeClass('move-right')