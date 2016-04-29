@Iconto.module 'shared.views.userProfile.verification', (Verification) ->
	class Verification.StatusView extends Marionette.ItemView
		className: 'verification-status-view mobile-layout'
		template: JST['shared/templates/user-profile/verification/status']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		ui:
			status: '.status'

		serializeData: =>
			_.extend @model.toJSON(), state: @state.toJSON()

		initialize: =>
			@model = new Backbone.Model(@options.user)

			# situation when phone is confirmed but info is not
			# we set personal info status to canceled
			phoneApproved = @model.get('personal_phone_status') is Iconto.REST.User.PERSONAL_PHONE_STATUS_APPROVED
			personalInfoStatusEmpty = @model.get('personal_info_status') is Iconto.REST.User.PERSONAL_INFO_STATUS_EMPTY
			@model.set personal_info_status: Iconto.REST.User.PERSONAL_INFO_STATUS_CANCEL if phoneApproved and personalInfoStatusEmpty

			# [wallet|office]/profile
			@page = Backbone.history.fragment.split('/').slice(0, 2).join('/')

			@state = new Iconto.shared.models.BaseStateViewModel _.extend {}, @options,
				isLoading: false
				topbarTitle: 'Статус заявки'
				breadcrumbs: [
					{title: 'Профиль', href: "/#{@page}"}
					{title: 'Статус заявки', href: document.location.pathname}
				]
				page: @page