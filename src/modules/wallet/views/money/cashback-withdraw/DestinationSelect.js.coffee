@Iconto.module 'wallet.views.money', (Money) ->
	class CardView extends Marionette.ItemView
		template: JST['wallet/templates/money/cashback-withdraw/card']
		className: 'flexbox card'
		attributes: ->
			'data-id': @model.get('id')

		events:
			'click': 'onClick'

		onClick: =>
			@trigger 'click', @model

	class WithdrawModel extends Backbone.Model
		defaults:
			phoneNumber: ''
		validation:
			phoneNumber:
				required: true
				pattern: 'phone'
	_.extend WithdrawModel::, Backbone.Validation.mixin

	class Money.CashbackWithdrawDestinationSelectView extends Marionette.CompositeView
		className: 'cashback-withdraw-destination-select-view mobile-layout form'
		template: JST['wallet/templates/money/cashback-withdraw/destination']
		childView: CardView
		childViewContainer: '.card-list'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
			Form:
				events:
					submit: 'form'
#
#		events:
#			'submit form': (e) -> e.preventDefault()

		validated: =>
			model: @model

		initialize: =>
			@wizardView = @options.view

			@model = new WithdrawModel()
			@collection = new Iconto.REST.CardCollection()

			@state = new Iconto.wallet.models.StateViewModel
				topbarTitle: 'Перевод CashBack'
				hasCards: false
#				breadcrumbs: [
#					{title: 'Мои карты', href: '/wallet/cards'}
#					{title: 'Перевод CashBack', href: '/wallet/money/withdraw'}
#				]
				phone: ''

		onRender: =>
			@collection.fetchAll(blocked: false, activated: true, {silent: true})
			.then (cards) =>
				cards = _.filter cards, (card) ->
					card.type is 0

				bankIds = _.uniq _.compact _.pluck cards, 'bank_id'
				(new Iconto.REST.BankCollection()).fetchByIds(bankIds)
				.then (banks) =>
					_.each cards, (card) ->
						card.bank = _.find banks, (bank) ->
							bank.id is card.bank_id
						card.bank ||= (new Iconto.REST.Bank()).toJSON()

					@collection.reset cards
					@state.set
						hasCards: @collection.length > 0
						isLoading: false
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onChildviewClick: (view, model) =>
			@wizardView.model.set cardId: model.get('id')
			@trigger 'transition:withdraw'

		onFormSubmit: (e) =>
			e.preventDefault()
			@wizardView.model.set phoneNumber: @model.get('phoneNumber')
			@trigger 'transition:withdraw'