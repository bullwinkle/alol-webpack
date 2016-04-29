#= require ./SubmitAttachmentItem

@Iconto.module 'chat.views', (Views) ->

	#	MAX_ATTACHMENTS_COUNT = 10
	MAX_ATTACHMENTS_COUNT = 4 # FIX FOR IOS

	class Views.SubmitView extends Marionette.CompositeView
		tagName: 'form'
		className: 'chat-submit-view'
		template: JST['chat/templates/submit']
		childView: Views.SubmitAttachmentItemView
		childViewContainer: '.attachments .list'

		behaviors:
			Epoxy: {}

		ui:
			form: 'form'
			input: '[name=body]'
			submit: '.submit-button'
			fileInput: 'input[type=file]'
			attachButton: '.attach'
			attachmentsCount: '.attach .count'
			addMoreAttachmentsButton: '.attachments button.add-more'
			reviewButton: 'button.review'

		events:
			'click @ui.submit': 'onSubmit'
			'keydown @ui.input': 'onInputKeyDown'
			'input @ui.input': 'onInputInput'
			'paste @ui.input': 'onInputInput'
			'change @ui.input': 'onInputInput'
			'click @ui.attachButton': 'onAttachButtonClick'
			'click @ui.addMoreAttachmentsButton': 'onAttachButtonClick'
			'change @ui.fileInput': 'onFileInputChange'
			'click @ui.reviewButton': 'onReviewButtonClick'

		collectionEvents:
			'add remove reset': 'onCollectionChange'

		initialize: =>
			@model = new Backbone.Model()

			# collection of attached images
			@collection = new Backbone.Collection()

			# company review model for SMILE, SAD, IDEA
			@companyReview = new Iconto.REST.CompanyReview()

			# action types for top buttons
			@ACTION_TYPES =
				TEXT: 0, FAQ: 1, SMILE: 2, SAD: 3, IDEA: 4

			# only review action types
			@REVIEW_ACTION_TYPES = [@ACTION_TYPES.SMILE, @ACTION_TYPES.SAD, @ACTION_TYPES.IDEA]

			@state = new Backbone.Model _.extend {}, @options,
				canWrite: true # FIX FOR IOS
				actionType: @ACTION_TYPES.TEXT
				FAQHeight: 0
				reviewId: 0
				reviewRoom: !!@options.reviewId
				isRatedReview: @options.isRatedReview

			# // Rupor is unnecessary now
			# isMessageReview: false

			# // Commented unless company has shop
			#	@state.set 'company', 'has_shop': false unless @state.get('company')

			# // Rupor is unnecessary now
			# @listenTo @state, 'change:isMessageReview', @onChangeMessageReview

			@sendMessagePrintedThrottled = _.throttle @sendMessagePrinted, 3000, leading: true, trailing: false

		onRender: =>
			# check if query has MESSAGE to auto insert in text field
			urlObj = Iconto.shared.helpers.navigation.parseUri()
			message = _.get urlObj, 'query.message'
			@ui.input.text message if message
			@ui.input.trigger 'change'

		onSubmit: =>
			# blur inputs
			@ui.input.blur()
			@ui.submit.blur()

			# get message text
			body = Iconto.shared.helpers.string.htmlToText @ui.input.html()

			# message initialization
			message = null

			# init attachments
			attachments = []

			if @state.get('canWrite') # FIX FOR IOS

				# check body length
				if body.length > 1024
					Iconto.shared.views.modals.Alert.show
						message: 'Ваше сообщение должно быть не более 1000 символов'
					return false

			unless (body or @collection.length > 0) and (@collection.all (attachment) -> attachment.get('success'))
				return false

			unless @state.get 'canWrite' # FIX FOR IOS
				attachments = @collection.map (attachment) ->
					type: 'ATTACHMENT_TYPE_IMAGE'
					image:
						id: attachment.get('file_id')
						url: attachment.get('url')
						url_original: attachment.get('url')

			if @state.get('actionType') in @REVIEW_ACTION_TYPES
				attachments = @collection.map (attachment) ->
					type: 'ATTACHMENT_TYPE_IMAGE'
					image:
						id: attachment.get('file_id')
						url: attachment.get('url')
						url_original: attachment.get('url')

				# create company review attachment
				companyReviewAttachment =
					type: Iconto.REST.Attachment.TYPE_META
					meta:
						type: 'company_review_create'
						id: @companyReview.get('type')
				attachments.push companyReviewAttachment
				console.warn 'review attachment', attachments

			@collection.reset()

			message = new Iconto.REST.Message
				id: _.uniqueId 'temp'
				body: body
				room_view_id: @options.chatId
				attachments: attachments
				user: @options.user
				type: Iconto.REST.Message.PRODUCER_TYPE_USER
				created_at: new Date().getTime() * 1000 #milliseconds

			message = message.toJSON()
			@submitMessage(message)
			@canWrite true # FIX FOR IOS

			@state.set actionType: @ACTION_TYPES.TEXT

		submitMessage: (message) =>
			# @state.set 'isMessageReview', false
			@trigger 'add-message-request', message
			@ui.input
			.empty()
			.trigger('change')
			.focus()

		onChildviewClick: (view, model) =>
			@canWrite true # FIX FOR IOS

			@collection.remove model

		onCollectionChange: =>
			length = @collection.length

			# update badge counter
			if length > 0
				@ui.attachmentsCount.text(length).show()
			else
				@ui.attachmentsCount.hide()

			# disable add attachments button if needed
			if 0 < length < MAX_ATTACHMENTS_COUNT
				@ui.addMoreAttachmentsButton.show()
			else
				@ui.addMoreAttachmentsButton.hide()

		onAttachButtonClick: =>
			body = Iconto.shared.helpers.string.htmlToText(@ui.input.html())

			# if no text in message OR action type is SMILE, SAD, IDEA
			if body.length is 0 or @state.get('actionType') in @REVIEW_ACTION_TYPES
				@ui.fileInput.get(0).click()

		onFileInputChange: =>
			files = @ui.fileInput.prop('files')
			return false unless files.length > 0

			MAX_FILE_SIZE = 5 #mb

			if files.length + @collection.length > MAX_ATTACHMENTS_COUNT
				attachmentDeclension = Iconto.shared.helpers.declension(MAX_ATTACHMENTS_COUNT,
					['вложение', 'вложения', 'вложений'])

				Iconto.shared.views.modals.Alert.show
					title: "Произошла ошибка"
					message: "Можно выбрать #{MAX_ATTACHMENTS_COUNT} #{attachmentDeclension}." # FIX FOR IOS
			else
				validFiles = []
				invalidFiles = []

				for file in files
					if file.size <= MAX_FILE_SIZE * 1024 * 1024
						validFiles.push
							id: _.uniqueId('file')
							file: file
					else
						invalidFiles.push file.name

				if validFiles.length > 0
					@collection.add validFiles

				if invalidFiles.length > 0
					invalidFileNames = '"' + invalidFiles.join('", "') + '"'
					declension = if invalidFiles.length is 1 then 'превышает' else 'превышают'
					errorMessage = "Максимальный размер файла: #{MAX_FILE_SIZE}мб. Файл #{invalidFileNames} #{declension} установленный лимит."

					Iconto.shared.views.modals.Alert.show
						title: 'Ошибка'
						message: errorMessage

			@ui.fileInput.val('')
			@canWrite false # FIX FOR IOS

			# override for SMILE, SAD, IDEA
			if @state.get('actionType') in @REVIEW_ACTION_TYPES
				@canWrite true

		# On RUPOR click (button near Send button, is hidden now)
		###
		onReviewButtonClick: =>
			unless @state.get('isMessageReview')
				@ui.reviewButton.blur()
				Iconto.shared.views.modals.Confirm.show
					message: "При выбранной опции, Ваше сообщение будет дублироваться отзывом на странице компании."
					submitButtonText: 'Подтвердить'
					onSubmit: =>
						@state.set 'isMessageReview', true
						@ui.input.focus()
					onCancel: =>
						@ui.input.focus()
			else
				@state.set 'isMessageReview', false
		###

		# toggle review button
		###
		onChangeMessageReview: =>
			method = if @state.get('isMessageReview') then 'addClass' else 'removeClass'
			@ui.reviewButton[method]('apply-review')
		###

		# handle Ctrl (Shift) + Enter keypress
		onInputKeyDown: (e) =>
			@sendMessagePrintedThrottled()
			if (e.keyCode or e.which) is 13 #enter is pressed
				if Modernizr.touch
					if e.ctrlKey
						e.stopPropagation()
						@onSubmit()
						return false
				else
					#desktop - check if shift is pressed
					unless e.shiftKey
						e.stopPropagation()
						@onSubmit()
						return false

		onInputInput: (e) =>
			gotMessageBody = !!_.result e, "currentTarget.innerText.trim"
			if gotMessageBody and !@ui.submit.hasClass 'active'
				@ui.submit.addClass 'active'
			else if !gotMessageBody and @ui.submit.hasClass 'active'
				@ui.submit.removeClass 'active'


		# emit PRINT event
		sendMessagePrinted: =>
			Iconto.ws.emit 'EVENT_MESSAGE_PRINTED', room_id: @options.room_id

		canWrite: (canWrite) =>
			@state.set canWrite: canWrite
			@ui.input.attr 'contenteditable', canWrite
			@ui.input.focus() if canWrite