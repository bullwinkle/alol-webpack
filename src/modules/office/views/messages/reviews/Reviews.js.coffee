@Iconto.module 'office.views.messages', (Messages) ->
	class ImageView extends Marionette.ItemView
		template: JST['office/templates/messages/reviews/image']
		className: 'image-view'

		triggers:
			'click': 'click'

	class ImagesView extends Marionette.CollectionView
		childView: ImageView
		className: 'image-collection'

		onChildviewClick: (view, obj) ->
			@trigger 'image:delete', obj.model

	class Messages.ReviewsView extends Marionette.LayoutView
		template: JST['office/templates/messages/reviews/reviews']
		className: 'reviews-view mobile-layout'

		behaviors:
			Epoxy: {}
			Layout: {}
			Form:
				submit: '[name=submit-review-button]'
				events:
					click: '[name=submit-review-button]'

		regions:
			imagesRegion: '.images-region'

		ui:
			submitReviewButton: '[name=submit-review-button]'
			uploadButton: '.upload-button'
			uploadInput: 'input[type=file]'
			typeSelect: '[name=type-select]'

		events:
			'click @ui.submitReviewButton': 'onSubmitReviewButtonClick'
			'click @ui.uploadButton': 'onUploadButtonClick'
			'change @ui.uploadInput': 'onUploadInputChange'

		initialize: ->
			@model = new Iconto.REST.CompanyReview
				company_id: @options.companyId

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarSubtitle: ''
				isLoading: false
				tabs: [
					{title: 'Сообщения', href: "/office/#{@options.companyId}/messages/chats"},
					{title: 'Рассылки', href: "/office/#{@options.companyId}/messages/deliveries"}
					{title: 'Добавить отзыв', href: "/office/#{@options.companyId}/messages/reviews", active: true}
				]

				phone: ''

			@listenTo @state, 'change:phone', (model, value, options) ->
				@model.set user_phone: "7#{Iconto.shared.helpers.phone.parse(value)}", {validate: @setterOptions.validate}

		onRender: ->
			@imagesView = new ImagesView collection: new Backbone.Collection()
			@listenTo @imagesView, 'image:delete', (model) ->
				@imagesView.collection.remove model
			@imagesRegion.show @imagesView

		#		onSubmitReviewButtonClick: (e) ->
		onFormSubmit: (e) ->
			imageIds = @imagesView.collection.pluck('id')

			# add image ids to model
			@model.set image_ids: @imagesView.collection.pluck('id')

			# save model
			@model.save()
			.then =>
				# reset fields
				@model.set
					user_phone: ''
					type: Iconto.REST.CompanyReview.TYPE_SMILE
					message: ''
					image_ids: []

				# reset select or die
				@ui.typeSelect.selectOrDie('update')

				# reset validation for FormBehavior
				@setterOptions.validate = false

				# reset state phone
				@state.set
					phone: ''

				# reset
				@imagesView.collection.reset()

				Iconto.shared.views.modals.Alert.show
					title: 'Добавление отзыва'
					message: 'Отзыв успешно добавлен'

			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error

		onUploadButtonClick: (e) ->
			return false if @imagesView.collection.length is 5
			@ui.uploadInput.click()

		onUploadInputChange: ->
			@uploadImage @ui.uploadInput.prop("files")[0]

		uploadImage: (file) ->
			MAX_FILE_SIZE = 5

			fileService = Iconto.shared.services.file
			fileService.read(file)
			.then (e) =>
				# file size in MB
				fileSize = e.total / 1024 / 1024
				if fileSize > MAX_FILE_SIZE
					throw status: 400777

				fileService.upload(file)
				.then (response) =>
					@imagesView.collection.add response
			.dispatch(@)
			.catch (error) ->
				console.error error
				error.msg = switch (error.status)
					when 400777 then "Размер файла не должен превышать #{MAX_FILE_SIZE}МБ."
					else
						error.msg
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@ui.uploadInput[0].value = ''