@Iconto.module 'office.views.company.settings', (Settings) ->

	###
	triggers:
		"faq:item:create"
		"faq:item:update"
	###

	class Settings.FAQuestionEditView extends Marionette.ItemView
		template: JST['office/templates/company/FAQ/faq-edit-question']
		className: 'company-address-layout mobile-layout'

		behaviors:
			Epoxy: {}
			Layout: {}
			Form:
				submit: '[type=submit]'
				events:
					submit: 'form'

		ui:
			form: 'form'
			topbarLeftButton: '.topbar-region .left-small'
			topbarRightButton: '.topbar-region .right-small'
			categorySelect: '[name=parent_id]'
			deleteButton: '.delete'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'
			'click @ui.deleteButton':  'onDeleteButtonClick'

		initialize: ->
			@model = new Iconto.REST.CompanyFAQ _.extend {}, _.get(@options, 'faq', {}),
				company_id: @options.companyId

			submitButtonText = if @model.isNew() then 'Добавить' else "Сохранить"
			@state = new Iconto.shared.models.BaseStateViewModel _.extend {}, @options,
				topbarTitle: 'FAQ'
				topbarSubtitle: 'вопрос'
				topbarLeftButtonClass: ''
				topbarLeftButtonSpanClass: 'ic-chevron-left'
				topbarRightButtonClass: 'text-button'
				topbarRightButtonSpanClass: ''
				topbarRightButtonSpanText: submitButtonText
				FAQcategories: null
				submitButtonText: submitButtonText
				isLoading:true

			@faqCategories = new Iconto.REST.CompanyFAQCollection()

		onRender: =>
			modelPromise = new Promise (resolve, reject) =>
				if @model.isNew()
					resolve('ok')
					@state.set 'isLoading', false
				else
					@model.fetch()
					.then resolve
					.dispatch(@)
					.catch reject

			modelPromise
			.catch (err)=>
				console.error err
				switch err.status
					when 200008
						Iconto.shared.views.modals.ErrorAlert.show
							title: 'Ошибка'
							message: 'Вопрос для FAQ не найден'
			.then =>
				query =
					filters: company_id: @options.companyId
					show: 'all'
				@faqCategories.fetch query, {parse:true}
			.then (categories) =>
#				@state.set 'FAQcategories', _.filter categories, (cat) => cat.id isnt @model.get('id')
				categories = @faqCategories.toJSON()
				if categories.length > 0
					@state.set 'FAQcategories', @faqCategories.toJSON()
			.dispatch(@)
			.catch (err) =>
				console.error err
			.done =>
				@model.trigger 'change:parent_id'
				@ui.categorySelect.selectOrDie()
				if !@faqCategories.length
					@ui.categorySelect.find('option[selected]').text('Нет категорий')
					@ui.categorySelect.selectOrDie('update')
					@ui.categorySelect.selectOrDie('disable')
				@state.set 'isLoading', false

		onTopbarLeftButtonClick: =>
			route = "/office/#{@options.companyId}/settings/messages"
			if App.workspace.currentView.mainRegion.hasView()
				Iconto.shared.router.navigate route, trigger: false
				@destroy()
#				Iconto.shared.router.navigate route, trigger: true
			else
				Iconto.shared.router.navigate route, trigger: true

		onTopbarRightButtonClick: =>
			@ui.form.submit()

		onDeleteButtonClick: (e) =>
			e.stopPropagation()
			@state.set 'isLoadingMore', true

			globalEvent = "faq:item:delete"			
			Iconto.events.trigger globalEvent, @model.toJSON()
			_.defer @onTopbarLeftButtonClick

#			.done =>
#				if @state and @state.set
#					@state.set 'isLoadingMore', false

		onFormSubmit: =>
			@state.set 'isLoadingMore', true
			globalEvent = "faq:item:#{if @model.isNew() then 'create' else 'update'}"
			@model.save()
			.then (res) =>
				Iconto.events.trigger globalEvent, res
				_.defer @onTopbarLeftButtonClick
			.dispatch(@)
			.catch (err)=>
				console.error err
				alertify.error(err.msg)
			.done =>
				@state.set 'isLoadingMore', false