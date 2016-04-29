@Iconto.module 'office.views.messages.deliveries.new', (New) ->

	class New.Layout extends Iconto.shared.views.wizard.BaseWizardLayout

		className: 'new-delivery-layout'

		config: =>
			root: 'newDelivery'
			views:
				newDelivery:
					viewClass: New.NewDeliveryView
					args: =>
						_.extend model: @model, @options
					transitions:
						contacts: 'contacts'
						confirm: 'confirm'
				contacts:
					viewClass: New.ContactsView
					args: =>
						_.extend model: @model, @options
					transitions:
						back: 'newDelivery'
				confirm:
					viewClass: New.ConfirmView
					args: =>
						_.extend model: @model, @options
					transitions:
						back: =>
							@model.unset('id')
							@transition 'newDelivery'

		initialize: =>
			@model = new Iconto.REST.Delivery company_id: @options.companyId
