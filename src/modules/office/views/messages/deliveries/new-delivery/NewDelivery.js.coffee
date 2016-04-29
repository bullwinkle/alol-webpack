@Iconto.module 'office.views.messages.deliveries.new', (New) ->
	class New.AddressItemView extends Marionette.ItemView
		className: 'address-item-view label-wrap'
		template: JST['office/templates/messages/deliveries/new-delivery/address-item']
		templateHelpers: =>
			selected: @options.address_id is @model.get('id')

	class New.NewDeliveryView extends Marionette.ItemView
		className: 'new-delivery-view mobile-layout'
		template: JST['office/templates/messages/deliveries/new-delivery/new-delivery']
		childView: New.AddressItemView
		childViewContainer: '.addresses'

		behaviors:
			Epoxy: {}
			Layout: {}
			Form:
				submit: '[name=submit]'
				events:
					click: '[name=submit]'

		ui:
			cancelButton: '[name=cancel]'
			contactsButton: '[name=contacts-button]'
			changeSenderName: '.change-sender-name'

		events:
			'click @ui.cancelButton': 'onCancelButtonClick'
			'click @ui.changeSenderName': 'onChangeSenderNameClick'

		triggers:
			'click @ui.contactsButton': 'transition:contacts'

		validated: =>
			model: @model

		modelEvents: =>
			'change:message': (model, message) =>
				@state.set 'message', message
#			'change:address_id': (model, value, options) =>
#				@$('select[name=address-id]').selectOrDie('update')

		childViewOptions: =>
			address_id: @model.get('address_id')

		initialize: =>
			@model = @options.model

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Новая рассылка'
				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal,
					leadingComma: true)}"
				breadcrumbs: [
					{title: 'Рассылки', href: "/office/#{@options.companyId}/messages/deliveries"},
					{title: 'Создание рассылки', href: "/office/#{@options.companyId}/messages/delivery/new"}
				]

				filterType: null
				message: ''
				addresses: []
				senderName: @options.company.sender_name || 'alol'
				canSendSms: !!@options.legal.id
				users_all: 0
				users_vip: 0
				users_novip: 0
				users_custom: 0

			@state.addComputed 'count',
				deps: ['message'],
				get: (message) ->
					count = Iconto.shared.helpers.sms.countSms(message)
					"#{count} #{Iconto.shared.helpers.declension(count, ['сообщение', 'сообщения', 'сообщений'])}"

			@listenTo @state,
				'change:filterType': @onFilterTypeChanged
				'change:senderName': @onSenderNameChange

			@collection = new Iconto.REST.AddressCollection()
			@companyClientCollection = new Iconto.REST.CompanyClientCollection()

		onRender: =>
			@$('select').selectOrDie()

			@collection.fetchAll(company_id: @options.companyId)
			.then (addresses) =>
				@state.set addresses: addresses

				# TODO: handle select updates
				# this code triggers select update
				addressId = @model.get('address_id')
				@model.set address_id: 0
				@model.set address_id: addressId

				@$('select').selectOrDie('update')
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

			allPromise = @companyClientCollection.count(company_id: @options.company.id)
			.then (allAmount) =>
				@state.set users_all: allAmount
				$opt = @$('[name=filter_all]')
				text = "#{$opt.text()} (#{allAmount})"
				$opt.text text

			vipPromise = @companyClientCollection.count(company_id: @options.company.id, is_vip: true)
			.then (vipAmount) =>
				@state.set users_vip: vipAmount
				$opt = @$('[name=filter_vip]')
				text = "#{$opt.text()} (#{vipAmount})"
				$opt.text text

			nonVipPromise = @companyClientCollection.count(company_id: @options.company.id, is_vip: false)
			.then (nonVipAmount) =>
				@state.set users_novip: nonVipAmount
				$opt = @$('[name=filter_nonvip]')
				text = "#{$opt.text()} (#{nonVipAmount})"
				$opt.text text

			customPromise = Promise.try =>
				customersCount = @model.get('customer_filter_ids').length
				if customersCount
					@state.set users_novip: customersCount
					$opt = @$('[name=filter_custom]')
					text = "#{$opt.text()} (#{customersCount})"
					$opt.text text
					$opt.prop('selected', true)

			Q.all([allPromise, vipPromise, nonVipPromise, customPromise])
			.then =>
				@$('[name=filter_custom]').prop 'selected', @model.get('customer_filter_ids').length > 0

				# option to tell onFilterTypeChanged not to transition!
				@state.set filterType: @getFilterType() || 'all', {onRender: true}
				@state.set isLoading: false

				@$('select').selectOrDie('update')
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		getFilterType: =>
			model = @model.toJSON()
			filterType = null
			if model.customer_filter_is_vip is undefined and model.customer_filter_ids.length is 0
				filterType = 'all'
			if model.customer_filter_is_vip is true
				filterType = 'vip'
			if model.customer_filter_is_vip is false
				filterType = 'nonvip'
			if model.customer_filter_ids.length
				filterType = 'custom'
			filterType

		onFormSubmit: =>
			if @model.get('sms_use')
				@model.unset('status')
				@model.save()
				.then (response) =>
					@model.set id: response.id
					@trigger 'transition:confirm'
				.dispatch(@)
				.catch (error) =>
					console.error error
					error.msg = switch error.status
						when 203144
							"Недостаточно средств"
						when 205111
							"Клиенты не найдены"
						when 208121, 205112
							"Текст сообщения слишком длинный"
						else
							error.msg
					Iconto.shared.views.modals.ErrorAlert.show error
			else
				@trigger 'transition:confirm'

		onFilterTypeChanged: (model, value, options) =>
			switch value
				when Iconto.REST.CompanyClient.FILTER_ALL
					@model.set
						customer_filter_ids: []
						customer_filter_is_vip: undefined
						users_count: @state.get('users_all')

				when Iconto.REST.CompanyClient.FILTER_VIP
					@model.set
						customer_filter_ids: []
						customer_filter_is_vip: true
						users_count: @state.get('users_vip')
				when Iconto.REST.CompanyClient.FILTER_NONVIP
					@model.set
						customer_filter_ids: []
						customer_filter_is_vip: false
						users_count: @state.get('users_novip')
				when Iconto.REST.CompanyClient.FILTER_CUSTOM
					@model.set
						users_count: @model.get('customer_filter_ids').length
						#customer_filter_ids: @state.get('selected')
						#customer_filter_is_vip: undefined
					unless options.onRender
						@trigger 'transition:contacts'

		onCancelButtonClick: =>
			# redirect
			Iconto.office.router.navigate "/office/#{@options.companyId}/messages/deliveries", trigger: true

		onChangeSenderNameClick: =>
			_this = @
			senderName = @state.get('senderName')

			Iconto.shared.views.modals.Prompt.show
				title: 'Имя отправителя'
				submitButtonText: 'Сохранить'
				value: senderName
				input: senderName
				onSubmit: ->
					_this.state.set senderName: @model.get('input')

		onSenderNameChange: (model, value, options) =>
			unless options.returnValue
				(new Iconto.REST.Company(id: @options.companyId)).save(sender_name: value)
				.catch (error) =>
					@state.set 'senderName', @state.previous('senderName'), {returnValue: true}
					@onChangeSenderNameClick()

					console.error error
					error.msg = switch error.status
						when 208120
							"Имя отправителя должно быть не менее 2\xa0символов"
						when 208121
							"Имя отправителя должно быть не более 11\xa0символов"
						else
							error.msg
					Iconto.shared.views.modals.ErrorAlert.show error