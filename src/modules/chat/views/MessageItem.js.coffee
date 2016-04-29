@Iconto.module 'chat.views', (Views) ->
	class Views.MessageItemView extends Marionette.ItemView
		className: 'message-item-view'
		template: JST['chat/templates/message-item']

		attributes: ->
			'data-same-author': =>
				sameAuthor = false

				collection = @model.collection

				if collection
					index = collection.indexOf(@model)

					model = @model.toJSON()
					previousModel = collection.at(index + 1)?.toJSON()

					if previousModel

						m = model
						pm = previousModel

						if (m.company_id and m.company_id is pm.company_id) or (m.user_id and m.user_id is pm.user_id)
							sameAuthor = true

				sameAuthor

			'data-room-view-id': =>
				@model.get('room_view_id')

			'data-seq-number': =>
				@model.get('sequence_number')

		ui:
			userLogo: '.user-logo img'
			info: '.info'
			sender: '.info .sender'
			attachments: '.attachments'
			notDelivered: '.not-delivered'
			resend: '[name=resend]'
			goToCompanyReviewChat: '.go-to-company-review-chat'
			likeDislike: '.like-dislike'
			likeDislikeButton: '.like-dislike > div'

		events:
			'click @ui.userLogo, @ui.sender': 'onClientClick'
			'click @ui.resend': 'onResendClick'
			'click @ui.goToCompanyReviewChat': 'onGoToCompanyReviewChatClick'
			'click @ui.likeDislikeButton': 'onLikeDislikeButtonClick'

		templateHelpers: =>
			isClient: =>
				@model.get('isClient')
			getImageUrl: =>
				model = @model.toJSON()
				Message = Iconto.REST.Message
				logo = switch model.type
					when Message.PRODUCER_TYPE_USER
						if model.user && model.user.image && model.user.image.id
							Iconto.shared.helpers.image.resize(model.user.image.url, Iconto.shared.helpers.image.FORMAT_SQUARE_SMALL)
					when Message.PRODUCER_TYPE_COMPANY, Message.PRODUCER_TYPE_DELIVERY
						if model.company && model.company.image && model.company.image.id
							Iconto.shared.helpers.image.resize(model.company.image.url,
								Iconto.shared.helpers.image.FORMAT_SQUARE_SMALL)
					when Message.PRODUCER_TYPE_SYSTEM
						window.ICONTO_TEAM_IMAGE

				logo ||= Iconto.shared.helpers.image.anonymous()

			getSenderName: =>
				model = @model.toJSON()
				Message = Iconto.REST.Message
				name = switch model.type
					when Message.PRODUCER_TYPE_USER
						user = model.user
						if user
							if user.first_name or user.last_name
								"#{user.first_name} #{user.last_name}"
							else if user.name
								user.name
							else
								user.nickname
						else
							'Аноним'
					when Message.PRODUCER_TYPE_COMPANY, Message.PRODUCER_TYPE_DELIVERY
						if model.company
							model.company.name
					when Message.PRODUCER_TYPE_SYSTEM
						'Команда АЛОЛЬ'
					when Message.PRODUCER_TYPE_REVIEW
						'Аноним'

		modelEvents:
			'change:user': 'onUserChange'
			'change:company': 'onCompanyChange'
			'change:notDelivered': 'onNotDeliveredChange'

		initialize: ->
			isCompany = !@model.get('room_view_id') or @model.get('room_view_id') is @options.roomViewId
			isMine = @model.get('user_id') is @options.user.id and isCompany
			isRead = isMine and @model.get('sequence_number') is @options.readSequenceNumber
			@model.set
				isClient: !isCompany
				isMine: isMine
				isRead: isRead
			@listenTo @model, 'change:read_at', @onModelReadAtChange
			@attachmentsPromise = Promise.pending()
			@model.set body: @model.get('body').replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

			@review = new Iconto.REST.CompanyReview()

		onRender: =>
			@ui.notDelivered.show() if @model.get('notDelivered')
			attachments = @model.get('attachments')
			if (attachments.length > 0)
				for attachment in attachments
					@parseAttachment(attachment)
				@attachmentsPromise.fulfill()

			reviewId = 0
			_.each @model.get('attachments'), (attachment) ->
				isMeta = _.get(attachment, 'type') is Iconto.REST.Attachment.TYPE_META
				isCompanyReview = _.get(attachment, 'meta.type') is 'company_review_resolve'
				reviewId = _.get(attachment, 'meta.id') if isMeta and isCompanyReview
			if reviewId
				@review.set(id: reviewId).fetch()
				.then (review) =>
					@ui.likeDislike.removeClass('hide').addClass("rating-#{review.rating}")
					if review.rating is Iconto.REST.CompanyReview.RATING_NONE
						@ui.likeDislike.removeClass('hide')
				.catch ->
					console.error error

		parseAttachment: (attachment) =>
			if attachment.type is Iconto.REST.Attachment.TYPE_IMAGE
				$attachment = $('<div></div>')
				.addClass('attachment image')
				.attr 'data-id': attachment.id
				.appendTo @ui.attachments

				imgSrc = "#{Iconto.shared.helpers.image.resize(attachment.image.url,
					Iconto.shared.helpers.image.FORMAT_SQUARE_LARGE)}"
				$img = $('<img></img>')
				.attr src: imgSrc
				.on 'click', @onImgAttachmentClick
				.appendTo $attachment

		onImgAttachmentClick: (e) =>
			imgSrc = _.get e, 'currentTarget.src'
			return false unless imgSrc
			imgSrcObj = Iconto.shared.helpers.navigation.parseUri imgSrc
			delete imgSrcObj.search # need to work with .query
			delete imgSrcObj.query.resize
			imgSrcFull = imgSrcObj.format()
			Iconto.shared.views.modals.LightBox.show
				img: imgSrcFull

		onUserChange: (model, user) =>
			@ui.userLogo.attr('src', @templateHelpers().getImageUrl())
			@ui.sender.text(@templateHelpers().getSenderName())

		onCompanyChange: (model, company) =>
			@ui.userLogo.attr('src', @templateHelpers().getImageUrl())
			@ui.sender.text(@templateHelpers().getSenderName())

		onNotDeliveredChange: (model, notDelivered) =>
			if notDelivered
				@ui.notDelivered.show()
			else
				@ui.notDelivered.hide()

		serializeData: =>
			model = @model.toJSON()
			createdAt = Math.floor(model.created_at / 1000)
			extensions =
				createdAt: moment(createdAt)
				readSequenceNumber: @options.readSequenceNumber
				isMine: model.user_id is @options.user.id and model.room_view_id is @options.roomViewId
			extensions.isRead = extensions.isMine and model.sequence_number is @options.readSequenceNumber

			extensions.showDate = false #do not show date by default

			#count start of day for the message
			startOfDay = extensions.createdAt.clone().startOf('day').valueOf();
			extensions.startOfDay = startOfDay

			previousCreatedAt = @options.dates[startOfDay];
			if not previousCreatedAt or previousCreatedAt >= createdAt
				extensions.showDate = true
				@options.dates[startOfDay] = createdAt
				_.defer =>
					@$el.closest('.list').find(".date:not([data-sequence-number=#{model.sequence_number}])[data-date=#{startOfDay}]").remove()

			_.extend model, extensions

		onModelReadAtChange: (model, readAt) =>
			@$el.closest('.messages').find('.is-read').remove()
			$('<div class="is-read">Прочитано</div>').appendTo @ui.info

		#		serializeData: =>
		#			#serialize model
		#			model = @model.toJSON()
		#
		#			#convert created_at to seconds
		#			createdAt = Math.floor(model.created_at/1000)
		#
		#			#prepare extensions
		#			additional =
		#				createdAt: moment(createdAt)
		#				showDate: false #do not show date label by default
		#
		#			#estimate the beginning of a day for the current message
		#			startOfDay = additional.createdAt.clone().startOf('day').valueOf()
		#			additional.startOfDay = startOfDay
		#			#check if there's already an entry for a message of the same day
		#			previousCreatedAt = @options.messageDateMap[startOfDay]
		#
		#			if previousCreatedAt #if there's one
		#				if createdAt < previousCreatedAt #check if current message was created earlier
		#					#update current date label:
		#					#remove existent
		#					_.defer =>
		#						@$el.closest('.messages').find(".date[data-date=#{startOfDay}]").each (index, label) ->
		#							if index > 0
		#								$(label).remove()
		#					#create new
		#					additional.showDate = true
		#					#update messageDateMap
		#					@options.messageDateMap[startOfDay] = createdAt
		#			else
		#				#not entry - create new
		#				additional.showDate = true
		#				#update messageDateMap
		#				@options.messageDateMap[startOfDay] = createdAt
		#
		#			additional.messageDateMap = @options.messageDateMap
		#
		#			_.extend model, additional

		onClientClick: =>
			if @model.get('isClient') then @trigger 'client:click', @model

		onResendClick: =>
			@trigger 'resend', @model

		onGoToCompanyReviewChatClick: ->
			isOffice = !!@options.companyId
			reviewId = 0

			attachments = @model.get('attachments')
			_.each attachments, (attachment) ->
				isMeta = _.get(attachment, 'type') is Iconto.REST.Attachment.TYPE_META
				isCompanyReview = _.get(attachment, 'meta.type') is 'company_review'
				reviewId = _.get(attachment, 'meta.id') if isMeta and isCompanyReview

			params = reviewId: reviewId
			params.fromOffice = isOffice

			Promise.try ->
				# get user id from company review or current user
				if isOffice
					(new Iconto.REST.CompanyReview(id: reviewId)).fetch()
					.then (companyReview) ->
						companyReview.user_id
				else
					Iconto.api.userId
			.then (userId) =>
				params.userId = userId

				Iconto.shared.helpers.messages.openChat(params)
				.then (response) =>
					url = "wallet/messages/chat/#{response.id}"
					url = "office/#{@options.companyId}/messages/chat/#{response.id}" if isOffice
					Iconto.shared.router.navigate url, trigger: true

		onLikeDislikeButtonClick: (e) ->
			isOffice = !!@options.companyId
			return false if isOffice

			return false unless @review.get('rating') is Iconto.REST.CompanyReview.RATING_NONE

			# get rating
			rating = Iconto.REST.CompanyReview.RATING_POSITIVE
			if $(e.currentTarget).hasClass('dislike')
				rating = Iconto.REST.CompanyReview.RATING_NEGATIVE

			@ui.likeDislike.removeClass("rating-#{@review.get('rating')}").addClass("rating-#{rating}")

			@review.set(rating: rating).save(rating: rating)
			.then =>
				@trigger 'review:click'
			.catch (error) ->
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error