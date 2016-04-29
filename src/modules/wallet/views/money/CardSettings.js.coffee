@Iconto.module 'wallet.views.money', (Money) ->
	class Money.CardSettings extends Marionette.ItemView
		className: 'card-settings-view mobile-layout'
		template: JST['wallet/templates/money/card-settings']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
			Form:
				submit: '[name=save-card]'
				events:
					click: '[name=save-card]'

		ui:
			topbarRightButton: '.topbar-region .right-small'
			cardDeleteButton: '[name=delete-card]'
			cardNameInput: '[name=title]'
			form: 'form'

		events:
			'click @ui.cardDeleteButton': 'onCardDeleteButtonClick'
			'submit @ui.form': 'onFormSubmit'

		validated: =>
			model: @model

		initialize: =>
			@model = new Iconto.REST.Card(id: @options.cardId)

			@state = new Iconto.wallet.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Настройка карты'

				cardTitle: ''
				breadcrumbs: [
					{title: 'Мои карты', href: "/wallet/cards"}
					{title: 'Детальная страница карты', href: "/wallet/money/card/#{@model.get('id')}"}
					{title: 'Настройка карты', href: "#"}
				]

			@listenTo @state, 'change:cardTitle', (model, value) =>
				@model.set title: value.trim()

		onRender: =>
			@model.fetch()
			.then =>
				@state.set
					isLoading: false
					cardTitle: @model.get('title')
				@buffer = new Iconto.REST.Card @model.toJSON()
			.done()

		onFormSubmit: (e) =>
			e.preventDefault()
			@model.validate()

			fields = (new Iconto.REST.Card(@buffer.toJSON())).set(@model.toJSON()).changed

			if @model.isValid() and not _.isEmpty fields
				@model.save(fields)
				.then () =>
					Iconto.shared.views.modals.Alert.show
						title: 'Сохранение'
						message: 'Изменения успешно сохранены.'
						onCancel: =>
							Iconto.wallet.router.navigate "/wallet/money/card/#{@model.get('id')}", trigger: true
				.catch (error) =>
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()

		onCardDeleteButtonClick: =>
			Iconto.shared.views.modals.Confirm.show
				title: 'Удаление карты'
				message: 'Вы уверены, что хотите отключить карту?'
				onSubmit: =>
					@model.destroy()
					.then ->
						Iconto.shared.views.modals.Alert.show
							title: 'Удаление'
							message: 'Карта успешно отключена.'
							onCancel: ->
								Iconto.wallet.router.navigate "/wallet/cards", trigger: true
					.catch (error) ->
						console.error error
						Iconto.shared.views.modals.ErrorAlert.show error
					.done()


