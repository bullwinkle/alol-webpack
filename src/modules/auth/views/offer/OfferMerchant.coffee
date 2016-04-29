@Iconto.module 'auth.views.offer', (Auth) ->

	class Auth.OfferMerchantView extends Marionette.ItemView
		className: 'offer-view'
		template: JST['auth/templates/offer-merchant']

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
			@company = new Iconto.REST.Company(id: @options.merchantId)
			@state = new Iconto.shared.models.BaseStateViewModel
				isLoading: false
				
			Iconto.shared.router.checkedOffer ||= {}
			Iconto.shared.router.checkedOffer.companyIds ||= []
				
		onRender: =>
			
			offerPromise = @offer.fetch {type: Iconto.REST.Offer.TYPE_MERCHANT, filters: ['last']}, {reload:true}
			companyPromise = @company.fetch()

			Q.all([ offerPromise, companyPromise ])
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@state.set isLoading: false
			
		onSubmitButtonClick: =>

			companyId = @company.get('id')
			@company.save
				accept_offer: true
				offer_num: @offer.get 'id'
			.then =>
				Iconto.shared.router.checkedOffer.companyIds.push companyId
				Iconto.auth.router.complete("/office/#{companyId}")
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
				title: 'Соглашение о сотрудничестве'
				message: 'Согласно правилам, вы не можете пользоваться сервисом, не приняв соглашение.'
				submitButtonText: 'В АЛОЛЬ'
				cancelButtonText: 'Вернуться к оферте'
				onSubmit: =>
					Iconto.commands.execute 'modals:closeAll'
					if Backbone.history.fragment is 'office'
						Iconto.office.router.navigate '/office'
					else
						Iconto.office.router.navigate '/office', trigger: true
			
