@Iconto.module 'office.views.company', (Company) ->
	class Company.BrandingView extends Marionette.ItemView
		template: JST['office/templates/company/branding']
		className: 'branding-settings-view mobile-layout'

		events:
			'click .topbar-region .left-small': 'onTopbarLeftButtonClick'
			'click .topbar-region .right-small': 'onTopbarRightButtonClick'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
			Form:
				submit: '[name=save-button]'
				events:
					click: '[name=save-button]'

		validated: =>
			model: @model

		initialize: =>
			@model = new Iconto.REST.CompanySettings(id: @options.companyId)
			@buffer = new Iconto.REST.CompanySettings()

			@listenTo @model,
				'change:background_color': (model, value) =>
					unless value
						@state.set background_color: ''
					else
						value = if Iconto.shared.helpers.color.luminance(value, 0.25).toLowerCase() is '#ffffff' then '' else value
						@state.set background_color: value
				'change:domain': @setDomain

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Брендированный вход'
#				breadcrumbs: [
#					{title: 'Компания', href: "office/#{@options.companyId}/profile"}
#					{title: 'Настройки брендированного входа', href: "#"}
#				]

				brandingUrl: ''
				companyImageUrl: @options.company.image.url
				background_color: ''
				border_color: '#ffffff'
				companyName: @options.company.name

		onRender: =>
			@model.fetch()
			.then =>
				@$('input.minicolors').minicolors(position: 'bottom left')
				@state.set isLoading: false
				@buffer.set @model.toJSON()
				@setDomain()
			.done()

		onFormSubmit: =>
			fields = (new Iconto.REST.CompanySettings(@buffer.toJSON())).set(@model.toJSON()).changed
			unless _.isEmpty fields
				@model.save(fields)
				.then =>
					@buffer.set @model.toJSON()
					Iconto.shared.views.modals.Alert.show
						title: 'Сохранено'
						message: 'Настройки брендированного входа успешно сохранены.'
				.catch (error) =>
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()

		setDomain: =>
			parsedUrl = Iconto.shared.helpers.navigation.parseUri(window.ICONTO_API_URL)
			domainName = @model.get('domain')
			domain = if domainName then domainName + '.' else ''
			brandingUrl = "#{parsedUrl.protocol}//#{domain}#{parsedUrl.host}"

			@state.set brandingUrl: brandingUrl