@Iconto.module 'office.views.offers', (Offers) ->
	class Offers.RequestEditView extends Marionette.ItemView
		className: 'request-view mobile-layout'
		template: JST['office/templates/offers/requests/request']

		ui:
			topbarRightButton: '.topbar-region .right-small'
			topbarLeftButton: '.topbar-region .left-small'
			approveButton: '[name=approve]'
			cancelButton: '[name=cancel]'
			deleteButton: '[name=delete]'

		events:
#			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
			'click @ui.approveButton': 'onApproveClick'
			'click @ui.cancelButton': 'onCancelClick'
			'click @ui.deleteButton': 'onDeleteButtonClick'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']


		modelEvents:
			'validated:valid': ->
				unless @isSaving
					status = @model.get('status')
					@ui.approveButton.removeAttr 'disabled'
					@ui.topbarRightButton.removeAttr 'disabled'
#					@ui.cancelButton.removeAttr 'disabled'
			'validated:invalid': ->
				@ui.approveButton.attr 'disabled', true
				@ui.topbarRightButton.attr 'disabled', true
#				@ui.cancelButton.attr 'disabled', true
			'change:type': 'onModelTypeChange'

		initialize: =>
			@state = new Iconto.office.models.StateViewModel @options
			@state.set
				topbarRightButtonClass: 'hide'

				canEditDiscount: false
				canDelete: false
				canAccept: false

				phone: ''

			@model = new Iconto.REST.DiscountCard id: @options.requestId
			@buffer = new Iconto.REST.DiscountCard id: @options.requestId

			@model.fetch({}, validate: false)
			.then (model) =>
				subtitle = switch @model.get('type')
					when Iconto.REST.DiscountCard.TYPE_PERSONAL_CASHBACK
						'Персональный CashBack'
					when Iconto.REST.DiscountCard.TYPE_WISH
						'Хочу привелегию'
					when Iconto.REST.DiscountCard.TYPE_DISCOUNT_CARD
						'Дисконтная карта'

				if @model.get('type') is Iconto.REST.DiscountCard.TYPE_PERSONAL_CASHBACK
					@state.set
						topbarRightButtonClass: ''
						topbarRightButtonSpanClass: 'ic-circle-checked'
					@ui.topbarRightButton.bind 'click', @onTopbarRightButtonClick

				@state.set
					topbarRightButtonClass: ''
					topbarRightButtonSpanClass: 'ic-circle-checked'
				@ui.topbarRightButton.bind 'click', @onTopbarRightButtonClick

				@buffer.set @model.toJSON()
			.done =>
				@state.set
					isLoading: false
				@state.on 'change:phone', (state, phone) =>
					@model.set 'phone', "7#{Iconto.shared.helpers.phone.parse phone}", validate: true
#					@model.validate()

		onRender: =>
			@ui.topbarRightButton.attr 'disabled', true
			Backbone.Validation.bind @

		onTopbarLeftButtonClick: =>
			@navigateBack()

		onTopbarRightButtonClick: =>
			@save()

		onApproveClick: =>
			@model.set status: Iconto.REST.DiscountCard.STATUS_APPROVED, {silent: true, validate: false}
			@save()

		save: =>
			@isSaving = true
			@ui.approveButton.attr 'disabled', true
			@ui.cancelButton.attr 'disabled', true
			@ui.topbarRightButton.attr 'disabled', true

			query = @buffer.set(@model.toJSON()).changed
			promise = Q.fcall =>
				unless _.isEmpty query
					@model.save query, silent: true, validate: false
				else
					true
			promise
			.then =>
				Iconto.shared.views.modals.Alert.show
					message: 'Изменения успешно сохранены'
					onCancel: =>
						@navigateBack()
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
				@ui.approveButton.removeAttr 'disabled'
				@ui.cancelButton.removeAttr 'disabled'
				@ui.topbarRightButton.attr 'disabled', true
			.done =>
				@isSaving = false

		onCancelClick: =>
			@isSaving = true
			@ui.approveButton.attr 'disabled', true
			@ui.cancelButton.attr 'disabled', true

			@model.save(status: Iconto.REST.DiscountCard.STATUS_CANCELLED, {silent: true, validate: false})
			.then =>
				Iconto.shared.views.modals.Alert.show
					message: 'Изменения успешно сохранены'
					onCancel: =>
						@navigateBack()
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
				@ui.approveButton.removeAttr 'disabled'
				@ui.cancelButton.removeAttr 'disabled'
				@ui.topbarRightButton.removeAttr 'disabled'
			.done =>
				@isSaving = false


		onModelTypeChange: (model, type) =>
			switch type
				when Iconto.REST.DiscountCard.TYPE_WISH
					canEditDiscount = true
					canDelete = false
					canAccept = true
				when Iconto.REST.DiscountCard.TYPE_DISCOUNT_CARD
					canEditDiscount = false
					canDelete = false
					canAccept = true
				when Iconto.REST.DiscountCard.TYPE_PERSONAL_CASHBACK
					canEditDiscount = true
					canDelete = true
					canAccept = false
				else
					canEditDiscount = false
					canDelete = false
					canAccept = false
			@state.set
				'canEditDiscount': canEditDiscount
				'canDelete': canDelete
				'canAccept': canAccept

		onDeleteButtonClick: =>
			@ui.deleteButton.attr 'disabled', true

			@model.destroy()
			.then =>
					@navigateBack()
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
				@ui.deleteButton.removeAttr 'disabled'
			.done()

		navigateBack: =>
			route = switch @model.get('type')
				when Iconto.REST.DiscountCard.TYPE_PERSONAL_CASHBACK
					"office/#{@state.get('companyId')}/offers/cashbacks/personal"
				when Iconto.REST.DiscountCard.TYPE_WISH
					"office/#{@state.get('companyId')}/offers/requests/wishes"
				else
					"office/#{@state.get('companyId')}/offers/requests"
			Iconto.office.router.navigate route, trigger: true

		onBeforeDestroy: =>
			@ui.topbarRightButton.unbind 'click'