@Iconto.module 'office.views.company', (Company) ->
	class Company.EditView extends Marionette.ItemView
		template: JST['office/templates/company/edit/edit']
		className: 'office-edit-view mobile-layout'

		behaviors:
			Epoxy: {}
			Layout:
				outlets:
					officeTopbar: JST['office/templates/office-topbar']
			Form:
				submit: '[name=save-button]'
				events:
					click: '[name=save-button]'

		ui:
			categorySelect: 'select'
			deleteButton: '[name=delete-button]'
			descriptionTextArea: '[name=description]'
			welcomeMessageTextArea: '[name=welcome_message]'

		events:
			'click @ui.deleteButton': 'onDeleteButtonClick'

		validated: ->
			model: @model

		serializeData: ->
			_.extend @model.toJSON(), company: @options.company

		initialize: =>

			if @options.company.rules_text and !@options.company.rules_url
				@options.company.rules_type = 'text'

			@model = new Iconto.REST.Company @options.company

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Редактирование компании'
				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal,
					leadingComma: true)}"
				breadcrumbs: [
					{title: 'Профиль', href: "office/#{@options.companyId}/profile"}
					{title: 'Настройки профиля компании', href: "#"}
				]
				isLoading: false
				officeTopbar:
					currentPage: 'edit'

				categories: []

			@mceEditors = []

		onRender: =>
#			@ui.descriptionTextArea.val @model.get 'description'

		onShow: =>
			if window.tinymce
				tinymceEditorEvents = ['input','paste','change','redo','undo']
				tinymce.init
					selector: '#description'
					#theme_url: '/tinymce/themes/modern/theme.min.js' # theme loaded by sprockets in vendors/index
					theme: 'modern'
					skin_url: '/tinymce/skins/lightgray'
					skin: "lightgray"
					language_url: '/tinymce/langs/ru_RU.js'
					language: 'ru_RU'
					statusbar: false
					templates: false
					menubar: false
					menu: {
						edit: {title: 'Edit', items: 'undo redo | cut copy paste pastetext | selectall'}
						insert: {title: 'Insert', items: 'link media hr'}
						format: {title: 'Format', items: 'bold italic underline strikethrough superscript subscript | removeformat'}
					}
					toolbar1: 'undo redo insertfile | bold italic | forecolor backcolor | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent '
					toolbar2: 'table link image media searchreplace hr | code fullscreen preview '
					plugins: [
						'anchor'
						'autolink'
						'autoresize'
						'charmap'
						'code'
						'colorpicker'
						'contextmenu'
						'fullpage'
						'fullscreen'
						'hr'
						'image'
						'imagetools'
						'insertdatetime'
						'layer'
						'legacyoutput'
						'link'
						'lists'
						'media'
						'paste'
						'preview'
						'searchreplace'
						'tabfocus'
						'table'
						'textcolor'
						'textpattern'
						'visualblocks'
						'visualchars'
					]
					setup: (editor) =>
						handler = _.debounce () =>
							val =  _.chain(editor)
							.result('getContent')
							.result('trim')
							.value()
							@model.set {description: val}, {validate:true}
						, 200
						_.each tinymceEditorEvents, (eventName) =>
							editor.on eventName, handler

				.then (editors) => _.each editors, (editor) => @mceEditors.push editor
				.catch (err) =>
					console.warn 'descriptionEditor error', err

		onBeforeDestroy: =>
			_.each @mceEditors, (editor) => _.result editor,'destroy'

		onAttach: =>
			(new Iconto.REST.CompanyCategoryCollection()).fetchAll()
			.then (categories) =>
				# set parent_id = 0 where null
				_.each categories, (category) ->
					category.parent_id ||= 0

				# group categories by parent_id
				groupedCategories = _.groupBy categories, (category) ->
					category.parent_id

				# sort top categories by name
				groupedCategories["0"] = _.sortBy groupedCategories["0"], (item) ->
					item.name

				groupedNamedCategories = {}

				# fill named categories like {"Auto": [..., ...], "Health": [..., ...]}
				_.each groupedCategories["0"], (item) ->
					groupedNamedCategories[item.name] = _.sortBy groupedCategories["#{item.id}"], (item) ->
						item.name

				@state.set categories: groupedNamedCategories
				@ui.categorySelect.selectOrDie()
			.dispatch(@)
			.catch (error) =>
				console.error error
			.done()

		onDeleteButtonClick: =>
			Iconto.shared.views.modals.Confirm.show
				title: 'Удаление компании'
				message: 'Вы уверены, что хотите удалить компанию?'
				onSubmit: =>
					@model.destroy()
					.then =>
						Iconto.shared.router.navigate "/office", trigger: true
					.dispatch(@)
					.catch (error) ->
						console.error error
						Iconto.shared.views.modals.ErrorAlert.show error
					.done()

		onFormSubmit: =>
			modelObj = @model.toJSON()
			fields = (new Iconto.REST.Company(@options.company)).set(modelObj).changed

#			if modelObj.rules_type isnt 'url' then delete fields.rules_url
			if _.isEmpty fields then return false

			_.each ['rules_url', 'site'], (field) =>
				return false unless fields[field]
				fields[field] = Iconto.shared.helpers.navigation.parseUri(fields[field]).href

			@model.save(fields)
			.then =>
				Iconto.shared.views.modals.Alert.show
					title: 'Готово'
					message: 'Данные компании успешно изменены'
					onCancel: =>
						Iconto.office.router.navigate "office/#{@options.company.id}/profile", trigger: true
			.dispatch(@)
			.catch (error) =>
				console.error error
				error.msg = switch error.status
					when 0 then "Произошла ошибка, попробуйте позже"
					else
						"Произошла ошибка, попробуйте позже"
				Iconto.shared.views.modals.ErrorAlert.show error
				console.log error
			.done()