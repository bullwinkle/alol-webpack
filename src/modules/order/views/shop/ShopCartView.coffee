#= require order/views/shop/ShopCartItemView

@Iconto.module 'order.views', (Views) ->

	class Views.ShopCartView extends Marionette.CompositeView
		template: JST['order/templates/shop/shop-cart']
		className: 'shop-checkout-view'
		childView: Views.ShopCartItemView
#		emptyView: Views.ShopCartEmptyView
		childViewContainer: '.list-container'
		behaviors:
			Epoxy: {}
			Form:
				handler: 'onFormSubmit'
				events:
					submit: 'form.summary'

		ui:
			checkoutForm: 'form.summary'
			phoneInput: '[data-user-phone]'
			totalPrice: '[data-total]'
			submitOrderButton: "[name=submit-order]"
			getLocationButton: '.get-location-button'
			deliveryDateInput: "[name=delivery_date]"
			deliveryDateInputDatePicker: "[data-is-datepicker=yes]"
			deliveryTimeInput: "[name=delivery_time]"
			fastDelivery: "[name=fast_delivery]"
			closeCartButton: ".close-cart"
			addressSelect: 'select[name=address_id]'

		events:
#			'click @ui.submitOrderButton': 'onFormSubmit'
			'click @ui.getLocationButton': 'onGetAddressStringButtonClick'
			'click @ui.closeCartButton': 'onCloseButtonClick'

		collectionEvents:
			'add remove update reset change': 'onCartCollectionChange'

		validated: =>
			model: @model

		childViewOptions: =>
			catalogOptions: @options.catalogOptions
			renderedIn: 'cart'
			# need to remove models from cart
			# TODO make item`s model.collection equal to @collection, not ShopCatalogCollection
			cartCollection: @collection

		initialize: ->
			@state = new Iconto.shared.models.BaseStateViewModel _.extend {}, @options.catalogOptions,
				orderSubmitted: false
				gotItems: @collection.length
				addresses: null

#			@listenTo @cartCollection, 'add remove update reset change', _.debounce @onCartCollectionChange, 100
#			@listenTo @collection, 'add remove reset', @onCartCollectionChange

			@parentView = @options.parentView if @options.parentView
			@ModelClass = Iconto.REST.ShopOrder
			@model = new Iconto.REST.ShopOrder()
			@order = new Iconto.REST.ShopOrder()
			@fastDeliveryWasApplied = false
			@company = new Iconto.REST.Company id: @state.get('company_id')
			@companyAddresses = new Iconto.REST.AddressCollection()

			company = @company.toJSON()
			@model.set
				phone: _.get(Iconto,'api.currentUser.phone','')
				min_amount: +company.shop_order_min_amount
#				threshold_amount: +company.shop_order_threshold_amount
#				delivery_amount: +company.shop_order_delivery_amount
#				delivery_full_amount: +company.shop_order_delivery_amount
#				delivery_discount_amount: +company.shop_order_delivery_discount_amount
#				delivery_date: ''
#				delivery_time: 0
#				delta_min_and_current_amount: 0
#				delivery_method: 1

				company_id: @state.get('company_id')
				address_id: @state.get('address_id')


			@listenTo @model,
				'validated:valid': -> console.warn 'valid', arguments
				'validated:invalid': -> console.warn 'invalid', arguments
				'change:delivery_date': @onDeliveryDateChange
#				'change:delivery_time': @onDeliveryTimeChange
				'change:delivery_method': @calcutaleTotals
				'change:fast_delivery': @onFastDeliveryChanged

			@calcutaleTotals()

		onRender: =>
			@ui.addressSelect.selectOrDie()
			@setOrderToModel()
			$('.view-content').scrollTop()

			Q.all [
				@company.fetch(),
				@companyAddresses.fetchAll company_id: @company.get('id')
			]
			.spread (company={},addresses=[]) =>
				@state.set 'addresses', addresses if addresses.length
				@ui.addressSelect.selectOrDie 'update'

		onShow: =>
#			@ui.deliveryDateInputDatePicker = @$ "[data-is-datepicker=yes]"
			@ui.phoneInput.change()

		onCartCollectionChange: =>
			@state.set 'gotItems', !!@collection.length
			@setOrderToModel()
			@calcutaleTotals()

#		onChildviewProductChange: (view, model) =>
#			model = view.model
#			@collection
#			.findWhere id: model.id
#			.set model.toJSON()

		onCloseButtonClick: =>
			parent = @parentView or _.result @,'_parentLayoutView'
			_.result parent, 'hideCheckout'

		onDeliveryDateChange: =>
			@model.set 'delivery_at', moment(@model.get('delivery_date')).add(1,'minute').unix()

#		onDeliveryTimeChange: =>
#			@model.set 'delivery_time', moment(@model.get('delivery_date')).unix()

		onGetAddressStringButtonClick: (e) =>
			@ui.getLocationButton.addClass 'is-loading'
			Iconto.shared.services.geo.getCurrentPosition()
			.then (geo) =>
				if geo.coords.latitude and geo.coords.longitude
					@getAddressString(geo.coords)
					.then (res) =>
						if res.data?.address and res.data?.address.length > 5
							@model.set 'address', res.data.address, validate:true
						else
							@ui.getLocationButton.removeClass 'is-loading'
							throw 'faild to define address'
					.catch (err) =>
						throw err
					.done =>
						@ui.getLocationButton.removeClass 'is-loading'
			.catch (err) =>
				console.error err
				@ui.getLocationButton.removeClass 'is-loading'
			.done()

		onFastDeliveryChanged: (model, fastDelivery, options) =>
			@calcutaleTotals()
			if fastDelivery then @fastDeliveryWasApplied = true
			now = moment()

			nowHour = +now.format('HH')
			workPeriods = @model.get 'workPeriods'
			startWorkHour = workPeriods[0][0]
			endWorkHour = workPeriods[workPeriods.length-1][1]
			currentWorkPeriodNumber = null
			if nowHour < startWorkHour
				currentWorkPeriodNumber = 0
			else if nowHour > endWorkHour
				currentWorkPeriodNumber = workPeriods.length-1
			else
				workPeriods.forEach (period, i) =>
					if period[0] <= nowHour <= period[1]
						currentWorkPeriodNumber = i
			if currentWorkPeriodNumber is workPeriods.length-1
				@ui.fastDelivery.prop 'disabled', true

			if fastDelivery
				if currentWorkPeriodNumber < workPeriods.length-1
					currentWorkPeriodNumber+=1
				deliveryDate = now.format('YYYY-MM-DD')
				@ui.deliveryDateInput.prop 'disabled', true
				@ui.deliveryDateInputDatePicker.prop 'disabled', true
				@ui.deliveryTimeInput.prop 'disabled', true
			else
				deliveryDate = now.add(1, 'day').format('YYYY-MM-DD')
				@ui.deliveryDateInput.prop 'disabled', false
				@ui.deliveryDateInputDatePicker.prop 'disabled', false
				@ui.deliveryTimeInput.prop 'disabled', false
			@model.set
				delivery_date: deliveryDate
				delivery_time: currentWorkPeriodNumber
#			@ui.deliveryDateInput.attr 'min', moment.unix(deliveryDate).format('YYYY-MM-DD')
			@ui.deliveryDateInputDatePicker
#			.attr 'min', moment.unix(deliveryDate).format('YYYY-MM-DD')
			.val moment.unix(deliveryDate).format('DD.MM.YYYY')

		getRoomView: =>
			roomView = new Iconto.REST.RoomView()
			reasons = []
			userId = @state.get('user').id
			companyId = @state.get 'company_id'
			return false if !userId and !companyId

			reasons.push {type: Iconto.REST.Reason.TYPE_USER, user_id: userId}
			reasons.push {type: Iconto.REST.Reason.TYPE_COMPANY, company_id: companyId}
			roomView.save(reasons: reasons)
			.dispatch(@)

		isOrderValid: (order) =>
			@model.validate()

			order = @model.toJSON()
			company = @company.toJSON()
			gotOrdered = @collection.find (model) =>
				model.get('count') > 0

			maxCount = Iconto.REST.ShopGood.prototype.validation.count.max
			toMachCount = @collection.find (model) =>
				model.get('count') > maxCount

			if !gotOrdered
				Iconto.shared.views.modals.Alert.show
					message: 'В заказе должен быть хотябы 1 товар.'
				return false

			if +order.amount < +company.shop_order_min_amount
				Iconto.shared.views.modals.Alert.show
					message: 'Сумма вашего заказа меньше минимальной.'
				return false

			if !!toMachCount
				Iconto.shared.views.modals.Alert.show
					message: "Вы не можете заказать товаров больше, чем #{maxCount} шт."
				return false

			return false if !@model.isValid()

			return true

		notifyIos: (event='', data=null) =>
			return console.error('notifyIos needs event name') unless event
			iosBridge = if window.__iContoBridge
				window.__iContoBridge
			else null

			unless iosBridge?.notify
				return false
			else
				iosBridge.notify event, {data}
				return true

		getAddressString: (coords) =>
			lat = coords.latitude
			lon = coords.longitude
			Iconto.api.get("#{ICONTO_API_URL}location/?lat=#{lat}&lng=#{lon}")

		setOrderToModel: =>
			productsToOrder = @collection.models
			.map (model) ->
				shop_good_id: +model.get('id')
				count: +model.get('count')
			.filter (product) ->
				product.count > 0

			@model.set
				'shop_goods': productsToOrder
#			,
#				validate: true

		calcutaleTotals: =>
			model = @model.toJSON()
			company = @company.toJSON()

			objToSet = {}
#			fastDelivery = model.fast_delivery

			objToSet.amount = amount = if @collection.length < 1 then 0 else
				@collection
				.map (model) ->
					+model.get('totalSum')
				.reduce (memo, value, index, collection) ->
					memo+=value

			amount = +amount or 0
			model.min_amount-=0
			model.min_amount-=0
#			model.threshold_amount-=0
#			model.delivery_discount_amount = +company.shop_order_delivery_discount_amount or 0

#			switch model.delivery_method
#				when 1
#					model.delivery_full_amount-= 0
#				when 2
#					model.delivery_full_amount = 0

			if model.min_amount and model.min_amount > amount
				deltaAmount = model.min_amount - amount
				objToSet.delta_min_and_current_amount = deltaAmount
			else
				objToSet.delta_min_and_current_amount = 0

#			if model.threshold_amount
#				if amount > model.threshold_amount
#					objToSet.delivery_amount = +company.shop_order_delivery_discount_amount
#				else
#					objToSet.delivery_amount = +company.shop_order_delivery_amount

#			else
#				objToSet.delivery_amount = +company.shop_order_delivery_amount


#			if fastDelivery
#				objToSet.delivery_amount+= 500
			#			else if @fastDeliveryWasApplied
			#				objToSet.delivery_amount-= 500

			objToSet.amount = +objToSet.amount.toFixed(2)
			objToSet.delta_min_and_current_amount = +objToSet.delta_min_and_current_amount.toFixed(2)
#			objToSet.delivery_amount = +objToSet.delivery_amount.toFixed(2)
#			objToSet.total_amount = +(amount + objToSet.delivery_amount).toFixed(2)
			objToSet.total_amount = +(amount).toFixed(2)

			@model.set objToSet

		onFormSubmit: =>
			return false unless @isOrderValid()

			Iconto.api.auth()
			.then =>
				(new @ModelClass()).save @model.toJSON()
			.then (res) =>
				@state.set 'orderSubmitted', true
				@trigger 'order:success', res

				waitFor = 3 #sec
				deffer = =>
					if waitFor
						@ui.submitOrderButton.text "Подождите #{waitFor} сек."
						waitFor--
					else
						clearInterval interval
						if @notifyIos 'form-submit'
							console.info 'notifyIos success'
							@collection.reset()
							if @parentView.showCatalog
								@parentView.showCatalog()
						else
							console.info 'send message and redirect to room'
							@getRoomView()
							.then (roomView) =>
								@collection.reset()

								if roomView.id
									route = "/wallet/messages/chat/#{roomView.id}"
									Iconto.shared.router.navigate route,
										trigger: true
										replace:true
								else
									if @state.get('navigateBack')
										routeToBack = @state.get('navigateBack')
										Iconto.shared.router.navigate routeToBack,
											trigger: true
											replace:true
									else Iconto.shared.router.navigateBack "/wallet/company/#{@company.get('id')}/shop"

							.catch (err) =>
								console.error err
								if @parentView.showCatalog
									@parentView.showCatalog()
							.done()

				deffer()
				interval = setInterval deffer, 1000

			.catch (err) =>
				console.error err

				@model.set 'orderSubmitted', false
				err.msg = switch err.status
					when 208122
						Iconto.shared.views.modals.Alert.show
							title: 'Ошибка'
							message: err.msg
							onCancel: =>
								if window.__iContoBridge
									@notifyIos 'form-submit'
								else @parentView.showCatalog()

					when 200002,  200005
						Iconto.shared.views.modals.PromptAuth.show
							preset: 'unauthorized'
							successCallback: =>
								@state.set 'user', {id: Iconto.api.userId}
								@ui.checkoutForm.submit()

							errorCallback: =>
								console.warn 'errorCallback'
					else
						showErr = false
						err.msg
						Iconto.shared.views.modals.Confirm.show
							title: 'Ошибка'
							message: 'Попробуйте позже'
							submitButtonText: 'Еще раз'
							onSubmit: => @parentView.showCatalog()
							cancelButtonText: 'Закрыть'
							onCancel: =>
								@notifyIos 'form-submit'
			.done()