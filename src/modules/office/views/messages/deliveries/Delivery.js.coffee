@Iconto.module 'office.views.messages', (Messages) ->
	class Messages.DeliveryView extends Marionette.ItemView
		template: JST['office/templates/messages/deliveries/delivery']
		className: 'delivery-view mobile-layout with-bottombar'

		behaviors:
			Epoxy: {}
			Layout: {}

		ui:
			topbarLeftButton: '.topbar-region .left-small'
			confirmButton: '[name=confirm-button]'
			cancelButton: '[name=cancel-button]'
			deleteButton: '[name=delete-button]'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
			'click @ui.confirmButton': 'onConfirmButtonClick'
			'click @ui.cancelButton': 'onCancelButtonClick'
			'click @ui.deleteButton': 'onDeleteButtonClick'

		initialize: =>
			@model = new Iconto.REST.Delivery(id: @options.deliveryId)

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Рассылка'
				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal,
					leadingComma: true)}"
				breadcrumbs: [
					{title: 'Рассылки', href: "/office/#{@options.companyId}/messages/deliveries"}
				]

				addressesText: ''
				contactsText: ''
				statusText: ''
				statusColor: ''
				pending: false
				running: true

		onRender: =>
			@model.fetch({}, reload: true)
			.then =>
				model = @model.toJSON()
				if model.status is Iconto.REST.Delivery.STATUS_PENDING
					@state.set pending: true
				unless model.status is Iconto.REST.Delivery.STATUS_RUNNING
					@state.set running: false
				@state.set contactsText: if model.customer_filter_ids.length > 0
					model.customer_filter_ids.length
				else if model.customer_filter_is_vip is true
					"По VIP контактам"
				else if model.customer_filter_is_vip is false
					"По всем не VIP контактам"
				else
					"По всем контактам"

				@state.set
					statusText: @model.getStatusText()
					statusColor: @model.getStatusColor()
					breadcrumbs: [
						{title: 'Рассылки', href: "/office/#{@options.companyId}/messages/deliveries"},
						{title: model.title, href: "/office/#{@options.companyId}/messages/delivery/#{model.id}"}
					]

				if model.address_id
					(new Iconto.REST.Address(id: model.address_id)).fetch()
					.then (address) =>
						@state.set addressesText: address.address
				else
					@state.set addressesText: 'По всем адресам'
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done (delivery) =>
				@state.set
					isLoading: false

		onConfirmButtonClick: =>
			return false if @onConfirmButtonClickLock
			@onConfirmButtonClickLock = true

			@ui.confirmButton.addClass 'is-loading'

			@model.save(status: Iconto.REST.Delivery.STATUS_RUNNING)
			.then =>
				@model.set status: Iconto.REST.Delivery.STATUS_RUNNING
				@state.set
					pending: false
					running: true
					statusText: @model.getStatusText()
					statusColor: @model.getStatusColor()
			.dispatch(@)
			.catch (error) =>
				console.error error
				error.msg = switch (error.status)
					when 203144 then 'Недостаточно средств на счете компании.'
					else
						error.msg
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@onConfirmButtonClickLock = false
				@ui.confirmButton.removeClass 'is-loading'

		onDeleteButtonClick: =>
			@model.destroy()
			.then =>
				@onCancelButtonClick()
			.catch (error) =>
				console.error error
				error.msg = 'Произошла ошибка. Повторите позже'
				Iconto.shared.views.modals.ErrorAlert.show error

		onCancelButtonClick: =>
			Iconto.office.router.navigate "/office/#{@options.companyId}/messages/deliveries", trigger: true