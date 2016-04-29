@Iconto.module 'office.views.company', (Company) ->
	class Company.Preview extends Marionette.LayoutView
		template: _.template ''
		className: 'preview-view'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['office/templates/profile/preview']


		events:
			'click .topbar-region .left-small': 'onTopbarLeftButtonClick'
			'click .topbar-region .right-small': 'onTopbarRightButtonClick'
			'click #spot-add-button': 'onSpotAddButtonClick'

		ui:
			spotDescription: '[name=spot_description]'
			spotAddButton: '#spot-add-button'

		bindingSources:
			company: new Iconto.REST.Company()

		initialize: =>
			@model = new Iconto.REST.CompanySettings(id: @options.companyId)
			@bindingSources.company = new Iconto.REST.Company(id: @options.companyId)

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Предварительный просмотр'

		onRender: =>
			@model.fetch()
			.then =>
				$('.inner-wrap, .main-section').css 'background-color', if @model.get('background_color') then @model.get('background_color') else '#3DACDB'
				@$('.quotes').css 'color', @model.get('background_color')
				@$('button.send').css 'background-color', @model.get('background_color')

				@bindingSources.company.fetch()
			.then =>
				@$el.addClass @model.get('origin').split('.')[0]
				@state.set
					isLoading: false
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onBeforeDestroy: =>
			$('.inner-wrap, .main-section').css 'background-color', '#ffffff'