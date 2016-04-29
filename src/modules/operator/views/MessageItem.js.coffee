@Iconto.module 'operator.views', (Views) ->
	class Views.MessageItemView extends Marionette.ItemView
		className: 'message-item-view'
		template: JST['operator/templates/message-item']

		attributes: ->
			'data-same-author': =>
				if @options.sameAuthor
					return @options.sameAuthor

				sameAuthor = false
				collection = @model.collection

				if collection
					index = collection.indexOf(@model)

					model = @model.toJSON()
					previousModel = collection.at(index - 1)?.toJSON()

					if previousModel

						m = model
						pm = previousModel
						sameAuthor = m.room_view_id is pm.room_view_id and m.type is pm.type

				sameAuthor

			'data-room-view-id': =>
				@model.get('room_view_id')

			'data-seq-number': =>
				@model.get('sequence_number')

			'data-user-id': =>
				if @model.get('user')
					@model.get('user').id

		ui:
			userLogo: '.user-logo img'
			info: '.info'
			sender: '.info .sender'
			attachments: '.attachments'
			notDelivered: '.not-delivered'
			resend: '[name=resend]'
			goToCompanyReviewChat: '.go-to-company-review-chat'

		events:
			'click @ui.resend': 'onResendClick'
			'click @ui.goToCompanyReviewChat': 'onGoToCompanyReviewChatClick'

		templateHelpers: ->
			getImageUrl: =>
				model = @model.toJSON()
				Message = Iconto.REST.Message

				logo = switch model.type
					when Message.PRODUCER_TYPE_USER
						if model.user and model.user.image and model.user.image.id
							Iconto.shared.helpers.image.resize(model.user.image.url, Iconto.shared.helpers.image.FORMAT_SQUARE_SMALL)
					when Message.PRODUCER_TYPE_COMPANY, Message.PRODUCER_TYPE_DELIVERY
						if model.company and model.company.image and model.company.image.id
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
							user.name or user.nickname or 'Аноним'
						else
							'Аноним'
					when Message.PRODUCER_TYPE_COMPANY, Message.PRODUCER_TYPE_DELIVERY
						_.get model, 'company.name', 'Компания'
					when Message.PRODUCER_TYPE_SYSTEM
						'Команда АЛОЛЬ'
					when Message.PRODUCER_TYPE_REVIEW
						'Аноним'

		serializeData: ->
			model = @model.toJSON()
			createdAt = Math.floor(model.created_at / 1000)

			extensions =
				createdAt: moment(createdAt)
				readSequenceNumber: @options.readSequenceNumber

			extensions.showDate = false

			#count start of day for the message
			startOfDay = extensions.createdAt.clone().startOf('day').valueOf();
			extensions.startOfDay = startOfDay

			@options.dates ||= 0
			previousCreatedAt = @options.dates[startOfDay]
			if not previousCreatedAt or previousCreatedAt >= createdAt
				extensions.showDate = true

			_.extend model, extensions

		initialize: =>
			isRead = @model.get('sequence_number') is @options.readSequenceNumber

			@model.set
				isClient: false
				isRead: isRead

			@model.set body: @model.get('body').replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")

		onRender: ->
			attachments = @model.get('attachments')
			if attachments.length
				for attachment in attachments
					@parseAttachment(attachment)

		parseAttachment: (attachment) ->
			if attachment.type is Iconto.REST.Attachment.TYPE_IMAGE
				$attachment = $('<div></div>')
				.addClass('attachment image')
				.attr('data-id': attachment.id)
				.appendTo(@ui.attachments)

				imgSrc = "#{Iconto.shared.helpers.image.resize(attachment.image.url,
					Iconto.shared.helpers.image.FORMAT_SQUARE_LARGE)}"
				$img = $('<img></img>')
				.attr src: imgSrc
				.on 'click', @onImgAttachmentClick
				.appendTo $attachment