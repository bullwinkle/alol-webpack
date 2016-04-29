@Iconto.module 'office.views.new', (New) ->
	class New.ImageView extends Marionette.ItemView
		template: JST['office/templates/new/image']
		className: 'image-view mobile-layout'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		ui:
			backButton: '[name=back-button]'
			continueButton: '[name=continue-button]'
			skipButton: '[name=skip-button]'
			dropArea: '.drop-area'
			uploadImage: '.upload-image'
			deleteImage: '.delete-image'
			uploadImageBlock: '.upload-image-block'
			progressBar: '.progress-bar'
			uploadInput: '.upload-input'
			loaderBubblesBlock: '.loader-bubbles-block'

		events:
			'click @ui.backButton': 'onBackButtonClick'
			'click @ui.continueButton': 'onContinueButtonClick'
			'click @ui.skipButton': 'onSkipButtonClick'

			'click @ui.dropArea': 'onDropAreaClick'
			'click @ui.deleteImage': 'onDeleteImageClick'

			'change @ui.uploadInput': 'onUploadInputChange'

			'dragover @ui.dropArea': 'onDropAreaDragOver'
			'drop @ui.dropArea': 'onDropAreaDrop'

		serializeData: =>
			@state.toJSON()

		initialize: =>
			@model = @options.company

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Заявка на управление компанией'
				isLoading: false
				stepIcons: @options.stepIcons
				step: 3

				hasImage: false

		onRender: =>
			if @model.get('image').url
				# set image if has any
				@ui.uploadImage.attr('src', @model.get('image').url).css(opacity: 1)

				# set state param
				@state.set hasImage: true

		onBackButtonClick: =>
			@trigger 'transition:back'

		onContinueButtonClick: =>
			unless @model.get('image_id')
				# if user clicked on continue button, warn about no image
				@ui.dropArea.addClass('blink')

				# remove blink class after 1 sec
				setTimeout =>
					unless @isDestroyed
						@ui?.dropArea?.removeClass('blink')
				, 1000
			else
				@trigger 'transition:legal'

		onSkipButtonClick: =>
			# clear fileds if skip button clicked
			@model.set
				image_id: 0
				image:
					id: 0
					url: ''

			@trigger 'transition:legal'

		onDeleteImageClick: (e) =>
			e.stopPropagation()

			@state.set hasImage: false

			@model.set
				image_id: 0
				image:
					id: 0
					url: ''

		onDropAreaDragOver: (e) =>
			e.preventDefault()

		onDropAreaDrop: (e) =>
			e.stopPropagation()
			e.preventDefault()

			file = e.originalEvent.dataTransfer.files[0]
			@uploadFile(file)

		onDropAreaClick: =>
			@ui.uploadInput.click()

		onUploadInputChange: =>
			if @ui.uploadInput.prop('files').length > 0
				file = @ui.uploadInput.prop('files')[0]
				@uploadFile(file)

		uploadFile: (file) =>
			return unless file.type.toLowerCase() in ['image/png', 'image/jpg', 'image/jpeg']

			fileService = Iconto.shared.services.file
			uploadOptions =
				onProgress: (progress) =>
					loadingPercents = (progress.loaded / progress.total * 100).toFixed(2)
					@ui.progressBar.css 'transform', "translateX(#{-(100 - loadingPercents)}%)"

			@ui.uploadImageBlock.addClass('reset')
			@ui.progressBar.css(transform: "translateX(-100%)")
			@ui.loaderBubblesBlock.removeClass 'hide' if @state.get('hasImage')

			fileService.read(file)
			.then (e) =>
				@ui.uploadImage.attr('src', e.target.result).css(opacity: 0.3)
				@state.set hasImage: true
				@ui.progressBar.css(opacity: 1)
				@ui.uploadImageBlock.removeClass('reset')
				@ui.loaderBubblesBlock.addClass 'hide'

				fileService.upload(file, uploadOptions)
			.then (data) =>
				@ui.progressBar.css(opacity: 0)
				@ui.uploadImage.css(opacity: 1)

				@model.set
					image_id: data.id
					image:
						id: data.id
						url: data.url

			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
				@state.set hasImage: false
			.done =>
				@ui.uploadInput[0].value = ''