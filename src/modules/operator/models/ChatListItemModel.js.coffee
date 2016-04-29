@Iconto.module 'operator.models', (Models) ->
	class Models.ChatListModel extends Backbone.Model
		defaults:
			room_id: ''
			room_view_id: ''
			group_id: ''

			chat_name: ''
			chat_image_url: ''
			chat_unread_amount: 0
			chat_additional_name: ''

			last_message_body: ''
			last_message_user_id: 0
			last_message_user_name: ''
			last_message_type: ''
			last_message_date: 0
			last_message_read_at: 0
			last_message_recieved_at: 0

			company_id: 0
			company_name: ''

			operator_id: 0
			operator_name: ''

			review_id: 0
			review_class: 'ic-face-smile'

			# additional fields
			room_view: {}
			group: {}
			room: {}
			company: {}
			last_message: {}
			operator: {}
			review: {}

	class Models.ChatListCollection extends Backbone.Collection
		model: Models.ChatListModel