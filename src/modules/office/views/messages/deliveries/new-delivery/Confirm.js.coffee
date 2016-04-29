@Iconto.module 'office.views.messages.deliveries.new', (New) ->
	class New.ConfirmView extends Marionette.ItemView
		className: 'confirm-view mobile-layout'
		template: JST['office/templates/messages/deliveries/new-delivery/confirm']

		behaviors:
			Epoxy: {}
			Layout: {}

		ui:
			saveButton: '[name=save]'
			submitButton: '[name=submit]'
			cancelButton: '[name=cancel]'

		events:
			'click @ui.saveButton': 'onSaveButtonClick'
			'click @ui.submitButton': 'onSubmitButtonClick'
			'click @ui.cancelButton': 'onCancelButtonClick'

		initialize: =>
			@model = @options.model
			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Создание рассылки'
				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal,
					leadingComma: true)}"
				isLoading: false
				address: ''

				breadcrumbs: [
					{title: 'Рассылки', href: "/office/#{@options.companyId}/messages/deliveries"},
					{title: 'Создание рассылки', href: "/office/#{@options.companyId}/messages/delivery/new"}
				]

				senderName: @options.company.sender_name || @model.get('sms_sender_name')

		onRender: =>
			addressId = @model.get('address_id')
			if addressId
				(new Iconto.REST.Address(id: addressId)).fetch()
				.then (address) =>
					@state.set address: address.address
			else
				@state.set address: 'По всем адресам'

		onSubmitButtonClick: =>
			return false if @onSubmitButtonClickLock
			@onSubmitButtonClickLock = true
			@ui.submitButton.addClass('is-loading')

			Promise.try =>
				if @model.get('sms_use')
					@model.save(status: Iconto.REST.Delivery.STATUS_RUNNING)
				else
					@model.save()
					.then =>
						@model.save(status: Iconto.REST.Delivery.STATUS_RUNNING)
			.then =>
				Iconto.office.router.navigate "/office/#{@options.companyId}/messages/deliveries", trigger: true
			.dispatch(@)
			.catch (error) =>
				console.error error
				error.msg = switch error.status
					when 203144
						"Недостаточно средств на депозите компании"
					when 205111
						"Клиенты не найдены"
					when 208121, 205112
						"Текст сообщения слишком длинный"
					else
						error.msg
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@onSubmitButtonClickLock = false
				@ui.submitButton.removeClass 'is-loading'

		onCancelButtonClick: =>
			# destroy model
			@model.destroy() if @model.get('sms_use')

			@trigger 'transition:back'

		onSaveButtonClick: =>
			if @model.get('sms_use')
				Iconto.office.router.navigate "/office/#{@options.companyId}/messages/deliveries", trigger: true
			else
				@model.save()
				.then =>
					Iconto.office.router.navigate "/office/#{@options.companyId}/messages/deliveries", trigger: true
				.dispatch(@)
				.catch (error) =>
					console.error error
					error.msg = switch error.status
						when 203144
							"Недостаточно средств на депозите компании"
						when 205111
							"Клиенты не найдены"
						when 208121, 205112
							"Текст сообщения слишком длинный"
						else
							error.msg
					Iconto.shared.views.modals.ErrorAlert.show error