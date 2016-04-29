@Iconto.module 'wallet.views.messages', (Messages) ->
	class Messages.SubmitView extends Iconto.chat.views.SubmitView
		className: 'chat-submit-view flexbox flex-column'
		template: JST['wallet/templates/messages/chats/submit']

		ui: _.extend Iconto.chat.views.SubmitView::ui,
			actionButton: '.actions .action'
			additionalRegion: '.additional-region'

		events: _.extend Iconto.chat.views.SubmitView::events,
			'click @ui.actionButton': 'onActionButtonClick'

		initialize: ->
			super()

			@state.set
				faqVisible: false
				faqAvailable: false
				faqReady: false

			# Company review for SMILE, SAD, IDEA.
			# Inherited model.
			#
			# @companyReview

			@listenTo @state, 'change:actionType', @toggleFAQ
			@on 'faq:hide', =>
				@state.set('actionType',0)


		onRender: ->
			super()

			companyId = @state.get('companyId')
			if companyId
				(new Iconto.REST.Company(id: companyId)).fetch()
				.then (company) =>
					@state.set 'company', company
				.catch (err) =>
					console.error err
				.done()

			_.defer @renderFAQtree

		renderFAQtree: =>
			@faqView = new Messages.FAQTreeView @options
			@faqView.render()
			@$el.append @faqView.$el
			@listenTo @state, 'change:faqVisible', (state, faqVisible, options) =>
				@faqView.trigger 'toggle:visible', faqVisible, state
				@trigger 'faq:change:visible', faqVisible, state

			@listenTo @faqView,
				'faq:ready': @onFAQViewReady
				'faq:question:send': @onFAQuestionSend

		onFAQViewReady: (FAQCollectionLength) =>
			@state.set
				faqReady: true
				faqAvailable: +FAQCollectionLength > 0
			@trigger 'faq:ready', FAQCollectionLength

		onFAQuestionSend: (question) =>
			questionAttach =
				'type': Iconto.REST.Attachment.TYPE_META
				'meta':
					'type': 'company_faq'
					'id': question.id

			message = new Iconto.REST.Message
				id: _.uniqueId 'temp'
				body: question.title
				room_view_id: @options.chatId
				attachments: [questionAttach]
				user: @options.user
				type: Iconto.REST.Message.PRODUCER_TYPE_USER
				created_at: new Date().getTime() * 1000 #milliseconds

			message = message.toJSON()
#			@submitMessage message
			@trigger 'add-message-request', message

			defer = =>
				@state.set 'actionType', 0
			setTimeout defer, 100

		# Click on action buttons handler: TEXT, FAQ, SMILE, SAD, IDEA.
		# Set @companyReview type specified in data-type attr.
		onActionButtonClick: (e) =>
			$el = $(e.currentTarget)

			# do nothing if click on active tab
			unless $el.hasClass('active')

				# remove from all buttons
				@ui.actionButton.removeClass('active')

				# add class to highlight icon
				$el.addClass('active')

				# set type
				actionType = +$el.data('type')

				dispatch =
					0: 0
					2: Iconto.REST.CompanyReview.TYPE_SMILE
					3: Iconto.REST.CompanyReview.TYPE_SAD
					4: Iconto.REST.CompanyReview.TYPE_IDEA

				@companyReview.set type: dispatch[actionType]
				@state.set actionType: actionType

		getHeight: =>
			faqListHeight = @$('.faq-list-view').outerHeight(true)
			messageBodyInputHeight = @$('.body-input-row').outerHeight(true)
			if faqListHeight > 500 then faqListHeight = 500
			else if faqListHeight < messageBodyInputHeight then faqListHeight = messageBodyInputHeight
			faqListHeight

		toggleFAQ: =>
			if @state.get('actionType') is @ACTION_TYPES.FAQ

				# next 3 lines need to enable FAQ only if FAQ isnt empty
				unless @state.get 'faqReady'
					return @once 'faq:ready', @toggleFAQ
				return false unless @state.get 'faqAvailable'

				@state.set
					faqVisible: true
					FAQHeight: @getHeight()
			else
				@state.set
					faqVisible: false
					FAQHeight: 0