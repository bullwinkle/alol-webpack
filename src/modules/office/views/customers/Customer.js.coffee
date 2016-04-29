@Iconto.module 'office.views.customers', (Customers) ->
	class Customers.CustomerView extends Marionette.ItemView
		className: 'customer-view mobile-layout'
		template: JST['office/templates/customers/customer']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
			Form:
				submit: '[name=save]'
				events:
					submit: 'form'


		ui:
			removeButton: 'button[name=remove]'
			topbarLeftButton: '.topbar-region .left-small'
			saveButton: 'button[name=save]'

		modelEvents:
			'change:source_type': (model, sourceType) ->
				@state.set 'sourceType', sourceType

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
			'click @ui.removeButton': 'onRemoveButtonClick'

		initialize: (@options) ->
			@model = new Iconto.REST.CompanyClient
				company_id: @options.companyId
				id: @options.customerId
			@buffer = @model.clone()

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal, leadingComma: true)}"
				phone: ''
				isSaving: false
				profileNickName: ""
				sourceType: Iconto.REST.CompanyClient.SOURCE_TYPE_UNKNOWN

			@state.addComputed 'isEditable',
				deps: ['sourceType'],
				get: (sourceType) =>
					sourceType in [
						Iconto.REST.CompanyClient.SOURCE_TYPE_MANUAL,
						Iconto.REST.CompanyClient.SOURCE_TYPE_FILE
					]

			_.extend @model.validation, external_id: {}

		onRender: =>
			Q.fcall =>
				if @model.isNew()
					@model.set source_type: Iconto.REST.CompanyClient.SOURCE_TYPE_MANUAL
					@state.set
						topbarTitle: 'Новый клиент'
						breadcrumbs: [
							{title: 'Клиенты', href: "office/#{@options.companyId}/customers"}
							{title: 'Добавление клиента', href: "#"}
						]
				else
					@model.fetch()
					.then (client) =>
						phone = Iconto.shared.helpers.phone.format7 client.phone

						@state.set
							topbarTitle: @model.getName()
							phone: phone
							profileNickName: "#{@model.get('first_name_orig') || ''} #{@model.get('last_name_orig') || ''}".trim()
							breadcrumbs: [
								{title: 'Клиенты', href: "office/#{@options.companyId}/customers"}
								{title: @model.getName(), href: "#"}
							]

						@model.set
							first_name: @model.get('first_name_display')
							last_name: @model.get('last_name_display')

						@buffer = new Iconto.REST.CompanyClient client
			.done =>
				@state.on 'change:phone', (state, phone) =>
					@model.set 'phone', "7#{Iconto.shared.helpers.phone.parse(phone)}", validate: @setterOptions.validate
				@state.set 'isLoading', false
			Backbone.Validation.bind @

		onFormSubmit: (e) =>
			e.preventDefault()
			return false unless @model.isValid(true)
			isNew = @model.isNew()

			query = _.pick @buffer.set(@model.toJSON()).changed,
				'is_vip', 'description', 'first_name', 'last_name', 'external_id'

			if isNew
				promise = (new @model.constructor()).save @model.toJSON()
			else
				promise = Q.fcall =>
					return false if _.isEmpty query
					@model.save query
			promise
			.then (companyClient) =>
				console.log(companyClient)

				return false unless companyClient
#				@model.clear().set @model.defaults
#				@buffer.clear().set @buffer.defaults
				message = if isNew
					'Клиент успешно добавлен'
				else
					'Изменения успешно сохранены'

				alertify.success message
				route = "/office/#{@state.get('companyId')}/customer/#{companyClient.id}/edit"
#				route = "/office/#{@state.get('companyId')}/customers"
				_.defer =>
					Iconto.office.router.navigate route, trigger: true, replace:true

			.dispatch(@)
			.catch (error) =>
				console.error error
				switch error.status
					when 213112
						#duplicate
						Iconto.shared.views.modals.Alert.show
							title: "Ошибка"
							message: "Пользователь уже добавлен в список клиентов."
					when 208121
						Iconto.shared.views.modals.Alert.show
							title: "Ошибка"
							message: "Идентификатор не может быть длиннее 25 символов"
					else
						Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onRemoveButtonClick: =>
			Iconto.shared.views.modals.Confirm.show
				title: "Подтвердите удаление"
				message: "Вы действительно хотите удалить пользователя?"
				onSubmit: =>
					@removeCustomer()
					true

		removeCustomer: =>
			@ui.removeButton.attr 'disabled', true

			@model.destroy()
			.then =>
				Iconto.office.router.navigate "office/#{@state.get('companyId')}/customers", trigger: true
			.catch (error) =>
				console.error error
				setTimeout =>
					Iconto.shared.views.modals.ErrorAlert.show error
				, 500
			.done =>
				@ui.removeButton.removeAttr 'disabled'