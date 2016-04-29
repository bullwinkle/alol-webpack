@Iconto.module 'payment.views', (Views) ->
	class Views.ProcessingView extends Marionette.LayoutView
		className: 'processing-view mobile-layout'

		template: JST['payment/templates/processing']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		bindingFilters:
			timeFromSeconds: (seconds) ->
				minutes = Math.floor(seconds / 60)
				seconds = seconds - minutes * 60

				if minutes < 10
					minutes = "0" + minutes
				if seconds < 10
					seconds = "0" + seconds
				minutes + ':' + seconds

		bindingSources: =>
			order: =>
				@order
			card: =>
				@card
			bank: =>
				@bank
			paymentSystem: =>
				@paymentSystem

		initialize: =>
			#model (Iconto.REST.Payment) is passed in @options
			@order = @options.order
			@card = new Iconto.REST.Card()
			@bank = new Iconto.REST.Bank()
			@paymentSystem = new Iconto.REST.PaymentSystem()

			@listenTo @order, 'change:status', @onOrderStatusChange
			@state = new Iconto.payment.models.StateViewModel()
			@state.set
				orderId: @order.get('id')
				topbarLeftButtonClass: ''
				topbarTitle: @order.get('description')

				isLoading: false
				timer: 60 * 5 #5 minutes

				status: @options.order.get('status')

				isCardRegistration: @order.get('type') is Iconto.REST.Order.TYPE_CARD_REGISTRATION
				isCardVerification: @order.get('type') is Iconto.REST.Order.TYPE_CARD_VERIFICATION

				orderUpdatedAt: ''

			@state.addComputed 'status_is_pending',
				deps: ['status'],
				get: (status) ->
					status is Iconto.REST.Order.STATUS_PENDING
			@state.addComputed 'status_is_processing',
				deps: ['status'],
				get: (status) ->
					status is Iconto.REST.Order.STATUS_PROCESSING
			@state.addComputed 'status_is_ready',
				deps: ['status'],
				get: (status) ->
					status is Iconto.REST.Order.STATUS_READY
			@state.addComputed 'status_is_error',
				deps: ['status'],
				get: (status) ->
					status is Iconto.REST.Order.STATUS_ERROR
			@state.addComputed 'status_is_completed',
				deps: ['status'],
				get: (status) ->
					status is Iconto.REST.Order.STATUS_COMPLETED
			@state.addComputed 'status_is_timeout',
				deps: ['status'],
				get: (status) ->
					status is Iconto.REST.Order.STATUS_TIMEOUT

		onRender: =>
			@onOrderStatusChange(@order, @order.get('status'))

		onBeforeDestroy: =>
			@order.stopPolling()
			@model.stopPolling()
			delete @['order']

		onOrderStatusChange: (order, status) =>
			@state.set 'status', status
			@order.stopPolling() unless status is Iconto.REST.Order.STATUS_PROCESSING
			switch status

				when Iconto.REST.Order.STATUS_PENDING
					@state.set 'status', Iconto.REST.Order.STATUS_PROCESSING
					@model.save()
					.then (payment) =>
						if @order.get('type') is Iconto.REST.Order.TYPE_CARD2CARD_TRANSFER
							@state.set 'status', Iconto.REST.Order.STATUS_PROCESSING
							@model.startPolling 60,
								error: (error) =>
									if error.status is 209103
										return true
									else
										@stopPolling()
										throw error
								success: =>
									if @model.get('3ds_url')
										@model.stopPolling()
										@process3ds()
						else
							@process3ds()
						#bypass startPolling result
						payment
					.catch (error) =>
						console.error error

						@order.stopPolling()
						@state.set 'status', Iconto.REST.Order.STATUS_ERROR

						error.msg = switch error.status
							when 208133
								"Вы ввели некорректный номер карты"
							else
								error.msg

						Iconto.shared.views.modals.ErrorAlert.show
							title: 'Произошла ошибка'
							message: error.msg

					.done()

				when Iconto.REST.Order.STATUS_PROCESSING
					@order.startPolling(300)

				when Iconto.REST.Order.STATUS_READY
					if @order.get('type') in [Iconto.REST.Order.TYPE_CARD_REGISTRATION, Iconto.REST.Order.TYPE_CARD_VERIFICATION]
						@processMoto()

				when Iconto.REST.Order.STATUS_COMPLETED
					if @order.get('type') is Iconto.REST.Order.TYPE_CARD_VERIFICATION
						(new Iconto.REST.Card(id: @order.get('source_card_id'))).invalidate()

					@card.set(id: @model.get('card_id')).fetch()
					.then (card) =>
						@paymentSystem.set(id: card.system_id).fetch() if card.system_id
						@bank.set(id: card.bank_id).fetch()
					.catch (error) =>
						console.error error
						Iconto.shared.views.modals.ErrorAlert.show error
					.done()

					@state.set orderUpdatedAt: moment.unix(order.get('updated_at')).format('DD MMM. YYYY, HH:mm')

					$('button.done').click =>
						redirectUrl = order.get('redirect_url')
						if redirectUrl
							if redirectUrl is 'success-payment.html'
								window.location.assign redirectUrl
							else
								@trigger 'transition:exit', redirectUrl

		process3ds: =>
			payment = @model.toJSON()
			url = payment['3ds_url']
			if url
				params = payment['3ds_params']
				$form = $("<form method=\"POST\"></form>").attr('action', url)
				if params
					for key, value of params
						$form.append $("<input type=\"hidden\"/>").attr(name: key, value: value)
				$form.appendTo('body').submit()
			else
				@order.startPolling(300)

		processMoto: =>
#			doVerify = (verificationCounter) =>
#				unless verificationCounter is 0
#					#popup
#					prompt = Iconto.shared.views.modals.Prompt.show
#						message: 'На вашей карте заблокирована случайная сумма от 1 до 10 руб. Введите эту сумму:'
#						type: 'number'
#						onBeforeCancel: =>
#							@trigger 'transition:exit', @order.get('error_redirect_url') or @order.get('redirect_url')
#							if @order.get('error_redirect_url') or @order.get('redirect_url')
#								true
#							else
#								false
#						onBeforeSubmit: =>
#							amount = prompt.model.get('input') - 0
#							return false unless amount
#
#							prompt.$(prompt.submitEl).attr 'disabled', true
#
#							#verify payment
#							Iconto.api.post('payment-verification', order_id: @order.get('id'), code: amount)
#							.then (response) =>
#								prompt.$(prompt.submitEl).removeAttr 'disabled'
#								throw response unless response.status is 0
#								#										prompt.hide()
#								if response.data.is_valid
#									@order.startPolling(300)
#								else
#									_.defer =>
#										Iconto.shared.views.modals.Alert.show
#											title: "Ошибка"
#											message: "Неправильная сумма."
#											onCancel: =>
#												#alert destroy - try again
#												_.defer =>
#													doVerify --verificationCounter
#							.catch (error) =>
#								console.error error
#								Iconto.shared.views.modals.ErrorAlert.show error
#							.done()
#							return true #close prompt
#				else
#					#tried 5 times - fail
#					@state.set 'status', Iconto.REST.Order.STATUS_ERROR
#
#			doVerify 5
			verificationCounter = 5
			prompt = Iconto.shared.views.modals.Prompt.show
				message: 'На вашей карте заблокирована случайная сумма от 1 до 10 руб. Введите эту сумму:'
				type: 'number'
				onBeforeCancel: =>
					@trigger 'transition:exit', @order.get('error_redirect_url') or @order.get('redirect_url')
					if @order.get('error_redirect_url') or @order.get('redirect_url')
						true
					else
						false
				onBeforeSubmit: =>
					amount = prompt.model.get('input') - 0
					return false unless amount

					--verificationCounter

					if verificationCounter is 0
						#tried 5 times - fail
						@state.set 'status', Iconto.REST.Order.STATUS_ERROR

						return true #close prompt


					prompt.$(prompt.submitEl).prop 'disabled', true

					#verify payment
					Iconto.api.post('payment-verification', order_id: +@order.get('id'), code: amount)
					.then (response) =>
						prompt.$(prompt.submitEl).prop 'disabled', false
						throw response unless response.status is 0

						if response.data.is_valid
							@order.startPolling(300)
							prompt.destroy()
							Iconto.commands.execute 'modals:close', prompt
#							return true #close prompt
						else
							prompt.$(prompt.inputEl).addClass 'has-validation-error'
							prompt.errorMessageEl.text "Неправильная сумма"

					.catch (error) =>
						console.error error
						Iconto.shared.views.modals.ErrorAlert.show error
					.done()

					return false #DO NOT close prompt

