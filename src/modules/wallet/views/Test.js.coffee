@Iconto.module 'wallet.views', (Views) ->

	class Views.TestView extends Marionette.LayoutView

		className: 'test-view mobile-layout'
		template: JST['wallet/templates/test']

		regions:
			cropper: '#cropper-region'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
			Form:
				submit: '[name=submit]'
				events:
					click: '[name=submit]'
					
		ui:
			uploadFile:'.file-upload'
			fileInput :'#file-input'
			filesNames: '.files-names'
			model: '#model'

		events:
			'click @ui.uploadFile' : 'onUploadFileClick'
			'click @ui.fileInput' : 'onFileInutClick'
			'change @ui.fileInput' : 'onFileInutChange'

		modelEvents:
			'change': 'onModelChange'
#			'change:time': -> console.log arguments
#			'change:date': -> console.log arguments

		validated: =>
			address: @address
			model: @model

		bindingSources: =>
			address: @address
			company: @company

		initialize: =>
			@state = new Iconto.wallet.models.StateViewModel @options
			@state.set
				isLoading: false

				items: [
					'one',
					{label: 'two', value: 'two-value!'},
					'three',
					{label: 'group', value: [
						'sub one',
						'sub two',
						'sub three'
					]}
				]

			@address = new Iconto.REST.Address id: 10012
			@company = new Iconto.REST.Company()
			@model = new Iconto.REST.CompanyClient()
			t = +moment()
			@model.set
				time: t
				date: t
				dateTime: t
				month: t

		onRender: =>
			cropperOptions =
				src: '/duck.jpg'
			cropperView = new Iconto.shared.views.Cropper cropperOptions
			@cropper.show cropperView

		onModelChange: =>
			console.log arguments
			@ui.model.text JSON.stringify(@model.toJSON(), null, '\t')

		onUploadFileClick: (e) =>
			console.info 'button.file-upload click'
			@ui.fileInput.click()
			
		onFileInutClick: (e) =>
			console.info 'input#file-input click'

		onFileInutChange: (e) =>
			console.info 'input#file-input change'
			files = e.target.files
			filesNames = _.pluck(files, 'name')
			@ui.filesNames.text filesNames.join ', '

		onFormSubmit: =>
			console.log 'submitting', @model.toJSON(), @address.toJSON(), @company.toJSON()
			Promise.delay(1000)

		preload: =>
			@address.fetch()
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error