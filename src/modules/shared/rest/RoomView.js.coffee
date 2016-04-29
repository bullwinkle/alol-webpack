class Iconto.REST.RoomView extends Iconto.REST.WSModel
	urlRoot: 'room_view'

	defaults:
		group_id: ''
		room_id: ''
		updated_at: 0
		group_updated_at: 0
		unread_amount: 0
		created_at: 0
		image: {}
		additional_group_names: ''
		name: ''
		visible: true
		blocked: false
		contact_phone: ''
		weigth: 0  # known mistake on erlang and ios
		operator_id: 0
		operator: {}
		room: {}
		group: {}

	setBlocked: (value) =>
		@sync('set_blocked', @, data: blocked: value)

	setVisible: (value) =>
		@sync('set_visible', @, data: visible: value)

	setOperator: (operatorId) =>
		@sync('set_operator', @, data: operator_id: operatorId)

class Iconto.REST.RoomViewCollection extends Iconto.REST.WSCollection
	url: 'room_view'
	model: Iconto.REST.RoomView

	parse: (data, options) =>
		switch data.type
			when 'COLLECTION_TYPE_ROOM_VIEW'
				data.room_views || []
			else
				data
