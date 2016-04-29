# TODO optimize image loading. Maybe read all files at first, then load...
@Iconto.module 'office.views.offers', (Offers) ->

	MAX_FILE_SIZE = 10 		#- Максимальный размер одного файла в mb
	MAX_FILES_COUNT = 10 	#- Максимальное количество загружаемых файлов

	inherit = Iconto.shared.helpers.inherit

	isFileQuantityValid = (filesLength) ->
		if filesLength > MAX_FILES_COUNT
			Iconto.shared.views.modals.Alert.show
				message: "Вы можете добавить не более #{MAX_FILES_COUNT} изображений"
			return false
		else return true

	isFileSizeValid = (file) =>
		if file.size/1024/1024 > MAX_FILE_SIZE then return false
		else return true

	class ImageView extends Marionette.ItemView
		template: JST['office/templates/offers/imagePreview']
		tagName: 'li'
		className: 'image-preview-wrapper'
		
		ui:
			image: '.image'
			removeButton: '.remove-button'
			progressBar: '.progress-bar .progress'
			progressBarText: '.progress-bar .text'

		events:
			'click @ui.image': 'onImageClick'
			'click @ui.removeButton': 'onRemoveButtonClicked'

		modelEvents:
			'change:url': 'onUrlChange'

		onRender: =>
			if @model.get('url')
				@model.set 'originalUrl', @model.get('url')
			else
				@listenToOnce @model, 'change:url', (model, value, options) =>
					@model.set 'originalUrl', @model.get('url')

			unless @model.get('upLoaded')
				return @uploadFile()
			@trigger 'image:uploaded'

		uploadFile: =>
			file = @model.get 'file'

			unless isFileSizeValid file
				console.log 'file is too big'
				@ui.progressBar.addClass 'error'
				@ui.progressBarText.text "Размер данного файла превышает лимит в #{MAX_FILE_SIZE} мб."
				@model.set 'error', true
				@trigger 'image:uploaded'
				return false

			uploadOptions =
				onProgress: (progress) =>
					loadingPercents = (progress.loaded/progress.total*100).toFixed(2)
					@ui.progressBar.css 'width', "#{loadingPercents}%"
					@ui.progressBarText.text "#{ loadingPercents }%"

			Iconto.shared.services.file.upload(file, uploadOptions)
			.dispatch(@)
			.then (data) =>
				unless data.url
					@ui.progressBar.addClass 'error'
					@ui.progressBarText.text "Невалидный тип файла - '#{file.type}'"
					@model.set 'error', true
					@trigger 'image:uploaded'
					return

				@ui.progressBar.addClass 'success'
				@model.set
					url: data.url
					upLoaded: true

			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@trigger 'image:uploaded'

		onRemoveButtonClicked: (e) =>
			console.log 'onRemoveButtonClicked'
			e.stopPropagation()
			collection = @model.collection
			collection.remove @model

		onImageClick: (e) =>
			lbx = Iconto.shared.views.modals.LightBox.show
				view: Iconto.shared.views.Cropper
				options:
					src: @model.get('originalUrl') or @model.get('url')

			lbx.$el.addClass('flex-centered')

			@listenTo lbx,
				'image:cropped': -> console.warn 'image:cropped'
				'image:uploaded': ([data]) =>
					@model.set 'url', data.url
					lbx.destroy()

		onUrlChange: (model, val, options) =>
			if model._previousAttributes?.url
				@ui.image.css "background-image": "url('#{val}')"

	class EmptyImageView extends Marionette.ItemView
		template: JST['office/templates/offers/emptyImagePreview']
		tagName: 'li'
		className: 'image-preview-wrapper empty'
		events: 'click': -> @trigger 'empty:click'

	class ImagesCollectionView extends Marionette.CollectionView
		tagName: 'ul'
		className: 'images-preview-list'
		emptyView: EmptyImageView
		childView: ImageView

		onChildviewImageUploaded: =>
			@trigger 'image:uploaded'

		onChildviewImageDeclined: =>
			@trigger 'image:declined'

		onChildviewEmptyClick: => @trigger 'empty:click'

	class Offers.PromotionEditView extends Offers.BaseOfferEditView

		ModelClass: Iconto.REST.Promotion
		
		template: JST['office/templates/offers/promotion/promotion-edit']
		className: 'promotion-edit-view mobile-layout'

		regions: inherit Offers.BaseOfferEditView::regions,
			imagesPreviewContainer: '.images-preview-container'

		behaviors: inherit Offers.BaseOfferEditView::behaviors
			
		ui: inherit Offers.BaseOfferEditView::ui,
			addImagesButton:'.add-images'
			imagesInput: '#images'
			imagesSelectButton: '[for=images]'
			imagesPreviewContainer: '.images-preview-container'
			imagesClearButton: '.clear-images'
			descriptionTextarea: 'textarea#description'

		events: inherit Offers.BaseOfferEditView::events,
			'change @ui.imagesInput': 'onFileInputChange'
			'click @ui.imagesClearButton': 'onClearImagesClick'
			'click @ui.addImagesButton' : 'onAddImagesClick'

		modelEvents: inherit Offers.BaseOfferEditView::modelEvents

		initialize: =>
			super()
			@commonModel.set
				entityName: 'Анонс'
				successSavedRoute: "office/#{@state.get('companyId')}/offers/promotions"
				objectType: Iconto.REST.PromoFeed.OBJECT_TYPE_PROMOTION

			@model = new @ModelClass
				id: @options.promotionId
				company_id: @options.companyId
				MAX_FILES_COUNT: MAX_FILES_COUNT
				
			modelIsNew = @model.isNew()
			pageTitle = "#{if modelIsNew then 'Создание нового' else 'Редактирование'} анонса"
			@state.set
				topbarTitle: pageTitle
				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal, leadingComma: true)}"
				breadcrumbs: [
					{
						title: 'Предложения',
						href: "/office/#{@options.companyId}/offers/promotions"
					},
					{
						title: pageTitle,
						href: "/office/#{@options.companyId}/offers/promotion/#{if modelIsNew then 'new' else @model.get('id')}"
					}
				]
				images: []
				multipleImages: true
				imagesCollectionEmpty: true

			@imagesCollection = new Backbone.Collection()
			@imagesCollectionView = new ImagesCollectionView collection: @imagesCollection
			@listenTo @imagesCollection, 'add remove reset', @onImagesCollectionChange
			@listenTo @imagesCollectionView, 'image:uploaded', @onImagesCollectionViewFileUploaded
			@listenTo @imagesCollectionView, 'empty:click', @onAddImagesClick

		onRender: =>
			super()
			@imagesPreviewContainer.show @imagesCollectionView
			promise = Q.fcall =>
				unless @model.isNew()
					@model.fetch({}, {validate: false})
					.dispatch(@)
					.then (objectData) =>
						@oldModelOnRender objectData
					.then =>
						@updateImages()
					.catch (error) =>
						console.error error
						@handleModelError error

				else
					@newModelOnRender()
					true
			promise
			.then =>
				@bindModelChangeWorkTimeEvents()
			.done =>
				@modelFetchingDone()

			@loadAddresses()

		onAddImagesClick: =>
			@ui.imagesInput.click()

		onFileInputChange: =>
			files = @ui.imagesInput[0].files
			return unless isFileQuantityValid(@imagesCollection.length+files.length)

			@state.set
				isSaving:true
				errorFiles: []

			@loadedCounter = 0
			@filesToUploadLength = files.length

			for file in files
				do (file) =>

					Iconto.shared.services.file.read(file)
					.then (e) =>
						if e.currentTarget.readyState is 2

							fileModel =
								file: file
								imgDataUrl: e.target.result
								imageId: _.uniqueId 'image-'
								upLoaded: false

							@imagesCollection.add fileModel

					.catch (error) ->
						console.error error
						Iconto.shared.views.modals.ErrorAlert.show error
					.done()

		onImagesCollectionChange: (model, collection, options) =>
			@state.set 'imagesCollectionEmpty', (collection.length > 0)

		onImagesCollectionViewFileUploaded: =>
			@loadedCounter++
			if @loadedCounter is @filesToUploadLength
				@onAllFilesAreLoaded()

		onAllFilesAreLoaded: =>
			if @state.get('errorFiles').length > 0
				message = if @state.get('errorFiles').length > 1
					"Максимальный допустимый размер загружаемого файла #{MAX_FILE_SIZE}мб. Размеры файлов \"#{@state.get('errorFiles').join('", "')}\" превышают установленный лимит."
				else
					"Максимальный допустимый размер загружаемого файла #{MAX_FILE_SIZE}мб. Размер файла \"#{@state.get('errorFiles')[0]}\" превышаeт установленный лимит."
				Iconto.shared.views.modals.ErrorAlert.show
					message: message
				@state.set 'errorFiles', []

			@ui.imagesInput[0].value = ''
			@state.set 'isSaving', false

		onClearImagesClick: =>
			Iconto.shared.views.modals.Confirm.show
				message: "Вы уверены, что хотите удалить все изображения?"
				onSubmit: =>
					@imagesCollection.reset()
					@ui.imagesInput.val('')
					@state.set 'isSaving', false

		updateImages: =>
			imageUrls = @model.get('images')
			resizeQuery = '?resize=height[250]-quality[80]'
			imageModels = for imageUrl in imageUrls
				imgDataUrl: imageUrl+resizeQuery
				url: imageUrl
				imageId: _.uniqueId 'image-'
				upLoaded: true

			@imagesCollection.add imageModels

		onFormSubmit: =>
			return unless isFileQuantityValid @imagesCollection.length

			Iconto.api.auth()
			.then =>
				imagesUrls = []
				@imagesCollection.each (image) ->
					unless image.get 'error'
						imagesUrls.push image.get 'url'
				@model.set 'images', imagesUrls
				@model.unset 'MAX_FILES_COUNT'

				addresses = @state.get('addresses') or []
				noAddresses = !addresses or !addresses.length

				if noAddresses
					return Iconto.shared.views.modals.Alert.show
						title: "Отсутствует адрес"
						message: "Для создания предложения у компании должен быть указан хотя бы 1 физический адрес. Его можно добавить в настройках профиля компании"

				super()

			.catch =>
				Iconto.shared.views.modals.PromptAuth.show preset: 'soft'