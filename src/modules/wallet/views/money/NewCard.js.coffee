@Iconto.module 'wallet.views.money', (Money) ->
	class Money.NewCardView extends Marionette.ItemView
		className: 'new-card-view mobile-layout'
		template: JST['wallet/templates/money/new-card']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		ui:
			input: 'input'
			cardAddButton: 'button[name=card-add-button]'

		events:
#			'click @ui.cardAddButton': 'onCardAddButtonClick'
			'submit form': 'onFormSubmit'

		initialize: =>
			@model = new Iconto.REST.Card()

			@state = new Iconto.wallet.models.StateViewModel @options
			@state.set
				topbarTitle: 'Новая карта'
				isLoading: false

				breadcrumbs: [
					{title: 'Мои карты', href: "/"}
					{title: 'Новая карта', href: "#"}
				]

		onFormSubmit: (e) =>
			e.preventDefault()
			@ui.input.blur()

			###
			 *  132 - Card number input must contain only digits
			 *  133 - Card number input is not from an allowed institute
			 *  134 - Card number input contains an invalid amount of digits
			 *  135 - Card number input seems to contain an invalid checksum
			 *  136 - Card number input seems to be an invalid credit card number
			###

			cardNumber = @model.get('card_number').replace(/\s/g, "")
			cardNumberRegExp = new RegExp(/^\d{12,25}$/)

			if cardNumberRegExp.test(cardNumber) and Iconto.shared.helpers.card.validateLuhn(cardNumber)
				@ui.cardAddButton.attr('disabled', true).addClass('is-loading')

				@model.save(card_number: cardNumber)
				.then =>
					Iconto.shared.views.modals.Alert.show
						title: 'Карта добавлена'
						message: 'Ваша карта успешно добавлена.'
						onCancel: =>
							Iconto.wallet.router.navigate "/wallet/cards", trigger: true
				.catch (error) =>
					console.error error
					error.msg = switch (error.status)
						when 307102 then 'Карта с такими данными уже зарегистрирована. Пожалуйста, свяжитесь со службой поддержки АЛОЛЬ, support@alol.io.'
						when 107129 then 'Вы можете привязать не более 8 карт.'
						when 208132 then 'Неверный номер банковской карты.'
						when 208133,208134,208135 then 'Неверный номер банковской карты.'
						else
							error.msg
					Iconto.shared.views.modals.ErrorAlert.show error
				.done =>
					@ui.cardAddButton.removeAttr('disabled').removeClass('is-loading')
			else
				Iconto.shared.views.modals.Alert.show
					title: 'Произошла ошибка'
					message: 'Пожалуйста, укажите корректный номер карты.'