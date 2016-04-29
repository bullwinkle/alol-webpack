@Iconto.module 'office.views.company.settings', (Settings) ->

	###
	triggers:
		"faq:category:create"
		"faq:category:update"
	###

	class Settings.FAQThemeEditView extends Marionette.ItemView
		template: JST['office/templates/company/FAQ/faq-edit-theme']
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
				topbarSubtitle: 'тема'
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
							message: 'Тема для FAQ не найдена'
			.then =>
				query =
					filters: company_id: @options.companyId
					show: 'all'
				@faqCategories.fetch query
			.then (categories) =>
#				@state.set 'FAQcategories', _.filter categories, (cat) => cat.id isnt @model.get('id')
				categories = @faqCategories.toJSON()
				if @faqCategories.length > 0
					@state.set 'FAQcategories', @faqCategories.parse categories
					@state.set 'flatFAQcategories', categories
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
#				Iconto.shared.router.navigate route, trigger: false
#				@destroy()
				Iconto.shared.router.navigate route, trigger: true
			else
				Iconto.shared.router.navigate route, trigger: true

		onTopbarRightButtonClick: =>
			@ui.form.submit()

		onDeleteButtonClick: (e) =>
			e.stopPropagation()

			flatFAQcategories = @state.get 'flatFAQcategories'
			id = @model.get 'id'
			found = _.find(flatFAQcategories, parent_id: id)
			unless @model.get('type') is Iconto.REST.CompanyFAQ.TYPE_CATEGORY and !!found
				@deleteEntity()
			else
				Iconto.shared.views.modals.Confirm.show
					title: 'Вы хотите удалить НЕ пустую категрию'
					message: 'При удалении категории все ее содержимое будет так же удалено.'
					onCancel: =>
						console.warn 'canceled'
					onSubmit: @deleteEntity

		deleteEntity: =>
			@state.set 'isLoadingMore', true
			globalEvent = "faq:category:delete"
			Iconto.events.trigger globalEvent, @model.toJSON()
			_.defer @onTopbarLeftButtonClick

		onFormSubmit: =>
			@state.set 'isLoadingMore', true
			globalEvent = "faq:category:#{if @model.isNew() then 'create' else 'update'}"
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