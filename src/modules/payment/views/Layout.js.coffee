@Iconto.module 'payment.views', (Views) ->
	class Views.Layout extends Iconto.shared.views.wizard.BaseWizardLayout

		className: 'payment-layout'

		config: =>
			root: @rootView
			views:
				payment:
					viewClass: Views.PaymentView
					args: =>
						order: @order
						model: @model
					transitions:
						processing: 'processing'
						'exit': =>
							Iconto.shared.helpers.navigation.tryNavigate @options.order.redirect_url if @options.order.redirect_url

				processing:
					viewClass: Views.ProcessingView
					args: =>
						order: @order
						model: @model
					transitions:
						back: =>
							@model.set @model.defaults, validate: true #reset payment model
							@transition 'payment'
						'exit': (exit_url) =>
							Iconto.shared.helpers.navigation.tryNavigate exit_url if exit_url

		initialize: =>
			@order = new Iconto.REST.Order @options.order
			@model = new Iconto.REST.Payment order_id: +@options.orderId
			@model.set order_type: @options.order.type
			if @options.order.status is Iconto.REST.Order.STATUS_PENDING
				if @options.order.type is Iconto.REST.Order.TYPE_CASHBACK_PAYOUT
					@rootView = 'processing'
				else
					@rootView = 'payment'
			else
				@rootView = 'processing'