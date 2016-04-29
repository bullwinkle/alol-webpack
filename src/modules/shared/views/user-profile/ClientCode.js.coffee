@Iconto.module 'shared.views.userProfile', (UserProfile) ->
	class UserProfile.ClientCodeView extends Marionette.ItemView
		className: 'mobile-layout clientcode-view'
		template: JST['shared/templates/user-profile/clientcode']

		behaviors:
			Epoxy: {}
			Layout: {}
			Form:
				submit: '.ic.ic-submit'
				events:
					click: '.ic.ic-submit'

		ui:
			skipButton: '[name=skip-button]'

		events:
			'click @ui.skipButton': 'onSkipButtonClick'

		initialize: ->
			@model = new Iconto.REST.CompanyClient(phone: @options.user.phone)
			@collection = new Iconto.REST.CompanyClientCollection()

			@state = new Iconto.shared.models.BaseStateViewModel _.extend {}, @options,
				topbarTitle: ''
				isLoading: false

		onFormSubmit: ->
			@state.set isLoading: true

			(new Iconto.REST.CompanyCollection()).fetch(alias: Iconto.REST.Company.ALIAS_ULMART)
			.then (companies) =>
				if companies.length
					params =
						company_id: companies[0].id
						phone: @options.user.phone
					@collection.fetch(params)
			.then (clients) =>
				if clients.length
					client = new Iconto.REST.CompanyClient(clients[0])
					client.save(external_id: @model.get('external_id'))
			.then ->
				Iconto.shared.router.navigate 'wallet/cards', trigger: true
			.catch (error) ->
				console.log error
				Iconto.shared.views.modals.ErrorAlert.show
					title: 'Ошибка'
					message: 'Произошла ошибка. Попробуйте еще раз позже'
			.catch (error) ->
				console.log error
				Iconto.shared.views.modals.ErrorAlert.show error
			.catch (error) ->
				console.log error
				Iconto.shared.views.modals.ErrorAlert.show error
			.then =>
				@state.set isLoading: false

		onSkipButtonClick: ->
			Iconto.shared.router.navigate 'wallet/cards', trigger: true