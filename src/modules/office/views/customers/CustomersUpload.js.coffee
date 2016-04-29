@Iconto.module 'office.views.customers', (Customers) ->
	class UploadModel extends Backbone.Model
		defaults:
			file: null
			obj: [1, 2, 3, [1, [1, 2, {foo: 'bar', bar: 'baz'}, [1, 2, 3]]]]
		validation:
			file:
				required: true
	_.extend UploadModel::, Backbone.Validation.mixin

	class Customers.CustomersUpload extends Marionette.CompositeView
		className: 'customers-upload-view mobile-layout'
		template: JST['office/templates/customers/customers-upload']

		behaviors:
			Epoxy: {}
			Layout: {}

		ui:
			form: 'form'
			fileInput: 'input[type=file]'
			fileSelectButton: '.file-select-button'
			fileUploadButton: '[name=file-upload-button]'
			fileName: '.file-name'

		events:
			'click .topbar-region .left-small': 'onTopbarLeftButtonClick'
			'click @ui.fileSelectButton': 'onFileSelectButtonClick'
			'click @ui.fileUploadButton': 'onFileUploadButtonClick'
			'change @ui.fileInput': 'onFileInputChange'
			'submit form': 'onFormSubmit'

		bindingSources: ->
			task: @task
			state: @state

		initialize: (@options) =>
			@model = new UploadModel()

			@task = new Iconto.REST.Task()

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Загрузка из файла'
				breadcrumbs: [
					{title: 'Клиенты', href: "office/#{@options.companyId}/customers"}
					{title: 'Загрузка из файла', href: "#"}
				]

				progressLoaded: 0
				progressTotal: 0
				processed: 0
				result: {}

			@state.addComputed 'progressPercents',
				deps: ['progressLoaded', 'progressTotal'],
				get: (loaded, total) ->
					Math.round(loaded / total * 100)
			@state.addComputed 'progressVisible',
				deps: ['progressPercents'],
				get: (percents) ->
					percents isnt 0 and percents isnt 100

		onRender: =>
			(new Iconto.REST.Company(id: @options.companyId)).fetch()
			.done (company) =>
				@state.set
					topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal,
						leadingComma: true)}"
			@state.set 'isLoading', false

		onFileInputChange: =>
			files = @ui.fileInput.prop('files')
			if files.length > 0
				@model.set 'file', files[0], validate: true
#				@ui.fileName.text files[0].name
#			else
#				@model.set 'file', 'Файл не выбран', validate: true
#				@ui.fileName.text 'Файл не выбран'

		onFileSelectButtonClick: (e) =>
			@ui.fileInput.click()

		getUploadUrl: =>
			dfd = $.ajax
				url: 'file'
				type: 'OPTIONS'
			Q(dfd)
			.then (response) =>
				throw response if response.status isnt 0
				response.data.file_upload_url

		onFileUploadButtonClick: =>
			files = @ui.fileInput.prop('files')
			return unless files.length > 0

			@task.set 'status', Iconto.REST.Task.TYPE_PROCESSING_STATUS
			@getUploadUrl()
			.then (uploadUrl) =>
				dfd = $.ajax
					url: uploadUrl
					type: 'POST'
					xhr: =>
						xhr = $.ajaxSettings.xhr()
						if xhr.upload.addEventListener
							xhr.upload.addEventListener 'progress', (e) =>
								if e.lengthComputable
									@state.set
										progressLoaded: e.loaded
										progressTotal: e.total
						xhr
					data: files[0]
					contentType: false
					processData: false

				Q(dfd)
				.then (response) =>
					if response.status is 0
						return response.data.id
					else
						throw response
				.then (fileId) =>
					@task.set
						type: Iconto.REST.Task.TYPE_IMPORT_COMPANY_CLIENTS_FROM_FILE
						args:
							file_id: fileId
							company_id: @state.get('companyId')

					@task.save()
					.then =>
						@checkTaskStatus(-1)
			.catch (error) =>
				console.error error
				@task.set 'status', Iconto.REST.Task.TYPE_ERROR_STATUS
			.done()

		clientDeclension: (number) ->
			"#{number} #{Iconto.shared.helpers.declension(number, ['клиент', 'клиента', 'клиентов'])}"

		#TODO: use Iconto.REST.Task.poll
		checkTaskStatus: (count) => #recursion causes stack overflow =*(
			counter = count if count
			@taskCheckInterval = setInterval =>
				return false if @isDestroyed

				if counter is 0
					#timeout
					clearInterval(@taskCheckInterval)
					@task.set 'status', Iconto.REST.Task.TYPE_ERROR_STATUS
				else
					#fetch

					@task.fetch({}, reload: true)
					.then (task) =>
						return false if @isDestroyed
						counter--
						if task.status isnt Iconto.REST.Task.TYPE_ERROR_STATUS
							#check if task is still processing
							if task.status isnt Iconto.REST.Task.TYPE_PROCESSING_STATUS
								#clear @taskCheckInterval
								clearInterval(@taskCheckInterval)

								if task.status is Iconto.REST.Task.TYPE_COMPLETED_STATUS
									task.clients ||= {}

									@state.set result: task.clients

									addedCount = _.get task, 'clients.added', 0
									duplicatedCount = _.get task, 'clients.duplicated', 0

									if addedCount > 0
#										message = "Успешно загружено #{@clientDeclension(addedCount)}."
#										if duplicatedCount > 0
#											message += " Продублировано #{@clientDeclension(duplicatedCount)}."
#										Iconto.shared.views.modals.Alert.show
#											title: 'Файл обработан'
#											message: message
#											onCancel: =>
#												Iconto.shared.router.navigate "office/#{@state.get('companyId')}/customers", trigger: true

									else
										clearInterval(@taskCheckInterval)
#										message = "Добавлено #{@clientDeclension(addedCount)}."
#										if duplicatedCount > 0
#											message += " Продублировано #{@clientDeclension(duplicatedCount)}."
#										Iconto.shared.views.modals.Alert.show
#											title: 'Файл обработан'
#											message: message
#											onCancel: =>
#												Iconto.shared.router.navigate "office/#{@state.get('companyId')}/customers", trigger: true

								#status is smth else
								if task.status is false
									Iconto.shared.router.navigate "office/#{@state.get('companyId')}/customers", trigger: true

							else
								processed = _.get(task, 'clients.added', 0) + _.get(task, 'clients.duplicated', 0) + _.get(task, 'clients.failed', 0)
								@state.set processed: @clientDeclension(processed)

						else
							clearInterval(@taskCheckInterval)
							Iconto.shared.views.modals.Alert.show
								title: 'Файл обработан'
								message: 'К сожалению, файл загрузить не удалось. Пожалуйста, проверьте, корректно ли он составлен и попробуйте загрузить заново.'
								onCancel: =>
									Iconto.shared.router.navigate "office/#{@state.get('companyId')}/customers", trigger: true
			, 1000