@Iconto.module 'auth.views.offer', (Auth) ->

	class Auth.OfferUserView extends Marionette.ItemView
		className: 'offer-view'
		template: JST['auth/templates/offer-user']

		behaviors:
			Epoxy: {}
		
		ui:
			cancelButton: '[name=cancel]'
			submitButton: '[name=ok]'
		
		events:
			'click @ui.cancelButton': 'onCancelButtonClick'
			'click @ui.submitButton': 'onSubmitButtonClick'
		
		initialize: (options) =>
			@offer = new Iconto.REST.Offer()
			@user = new Iconto.REST.User()
			@state = new Iconto.shared.models.BaseStateViewModel
				isLoading: true

			Iconto.shared.router.checkedOffer ||= {}
			Iconto.shared.router.checkedOffer.currentUser ||= false
				
		onRender: =>
						
			offerPromise = @offer.fetch {type: Iconto.REST.Offer.TYPE_USER, filters: ['last']}, {reload:true}
			userPromise = Iconto.api.auth()

			Q.all([userPromise, offerPromise])
			.then ([user, offer]) =>
				@user.set user
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set isLoading: false

		onSubmitButtonClick: =>
			@user.save
				is_offer_accepted: true
				offer_version: @offer.get 'id'
			.then =>
				Iconto.shared.router.checkedOffer.currentUser = true
				Iconto.auth.router.complete()
			.catch (error) =>
				console.error error
				switch error.status
					when 101107 # user not found -> need authorization
						Iconto.shared.router.navigate '/', trigger: true
					else
						error.msg = 'Доступ запрещен.'
						Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onCancelButtonClick: =>
			Iconto.shared.views.modals.Confirm.show
				title: 'Правила АЛОЛЬ '
				message: 'Согласно правилам, вы не можете пользоваться сервисом, не приняв оферту.'
				submitButtonText: 'Выйти из АЛОЛЬ '
				cancelButtonText: 'Вернуться к оферте'
				onSubmit: =>
					Iconto.api.logout()
					.then =>
						Iconto.commands.execute 'modals:closeAll'
						Iconto.shared.router.action '/auth'

					.catch (error) =>
						console.error error
						Iconto.shared.views.modals.ErrorAlert.show error
					.done()
			
