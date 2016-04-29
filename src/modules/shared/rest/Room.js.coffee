class Iconto.REST.Room extends Iconto.REST.WSModel
	urlRoot: 'room'

	defaults:
		created_at: 0
		updated_at: 0
		message_amount: 0
		last_message: null

class Iconto.REST.RoomCollection extends Iconto.REST.WSCollection
	url: 'room'
	model: Iconto.REST.Room

	parse: (data, method) =>
		switch data.type
			when 'COLLECTION_TYPE_ROOM'
				data.rooms
			else
				data
