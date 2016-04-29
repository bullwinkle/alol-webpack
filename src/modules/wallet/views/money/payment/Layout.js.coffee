@Iconto.module 'wallet.views.money.payment', (Payment) ->
	class Payment.Layout extends Marionette.LayoutView
		className: 'money-payment-layout mobile-layout form'
		template: JST['wallet/templates/money/payment/layout']

		regions:
			additionalFieldsRegion: '[name=additional-fields]'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		ui:
			providerCategoriesSelect: '#provider-categories'
			providersSelect: '#providers'

		initialize: =>
			@state = new Iconto.wallet.models.StateViewModel @options
			@state.set
				topbarTitle: 'Оплата'

				providerCategories: []
				providerCategoryId: undefined

				providers: []
				providerId: undefined

			@state.on 'change:providerCategoryId', @onStateProviderCategoryIdChange
			@state.on 'change:providerId', @onStateProvideIdChange

			@providerCategoryCollection = new Iconto.REST.ProviderCategoryCollection()

		onRender: =>
			@providerCategoryCollection.fetchAll()
			.then (categories) =>
				@state.set
					providerCategories: categories.map (c) ->
						label: c.name, value: c.id
					isLoading: false
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onStateProviderCategoryIdChange: (state, providerCategoryId) =>
			@state.set
				providerId: undefined
				providers: []

			@additionalFieldsRegion.reset()

			sod = @ui.providersSelect.closest('.sod_select').addClass('is-loading')

			(new Iconto.REST.ProviderCollection()).fetchAll(provider_category_id: providerCategoryId)
			.then (providers) =>
				@state.set
					providers: providers.map (p) ->
						_.extend p, label: p.name, value: p.id

				sod.removeClass('is-loading')
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onStateProvideIdChange: (state, providerId) =>
			providerId -= 0

			@additionalFieldsRegion.reset()

			provider = _.find @state.get('providers'), (p) ->
				p.id == providerId

			@state.set provider: provider

			if provider
				additionalFieldsView = new Payment.AdditionalFieldsView
					provider: provider
					onFormSubmit: =>
						@trySubmit additionalFieldsView.fieldsModel.serialize(), additionalFieldsView.model.serialize()
				@additionalFieldsRegion.show additionalFieldsView

		trySubmit: (fieldsData, amountData) =>
			order = new Iconto.REST.Order
				type: Iconto.REST.Order.TYPE_MONETA_PROVIDER_PAYMENT
				amount: amountData.amount
				provider_id: @state.get('providerId')-0
				fields: fieldsData
				redirect_url: "#{document.location.origin}/wallet/money/cashback"
			order.save()
			.then (response) =>
				order.invalidate()
				payment = new Iconto.REST.Payment
					order_id: response.order_id
				payment.save()
				.then (paymentResponse) =>
					(new Iconto.REST.User(id: @options.user.id)).invalidate()
					Iconto.wallet.router.navigate "/wallet/payment?order_id=#{response.order_id}", trigger: true
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error

