class Iconto.REST.Message extends Iconto.REST.WSModel
	module: 'chat'
	urlRoot: 'message'

	@PRODUCER_TYPE_COMPANY = 'PRODUCER_TYPE_COMPANY'
	@PRODUCER_TYPE_USER = 'PRODUCER_TYPE_USER'
	@PRODUCER_TYPE_SYSTEM = 'PRODUCER_TYPE_SYSTEM'
	@PRODUCER_TYPE_DELIVERY = 'PRODUCER_TYPE_DELIVERY'
	@PRODUCER_TYPE_REVIEW = 'PRODUCER_TYPE_REVIEW'

	@OPTION_REVIEW = 'REVIEW'

	defaults:
		body: ''
		created_at: 0
		id: 0
		room_id: 0
		sender_name: ''
		type: 0
		user_id: 0

		attachments: []

		sequence_number: 0

		#additional
		received_at: 0
		read_at: 0
		sent_at: 0

	validation:
		room_id:
			required: true
			min: 1
		user_id:
			required: true
			min: 1

_.extend Iconto.REST.Message::, Backbone.Validation.mixin

class Iconto.REST.MessageCollection extends Iconto.REST.WSCollection
	module: 'chat'
	url: 'message'
	model: Iconto.REST.Message

	parse: (data) =>
		switch data.type
			when 'COLLECTION_TYPE_MESSAGE'
				data.messages or []
			else
				data
