class Iconto.REST.Group extends Iconto.REST.WSModel
	urlRoot: 'group'

	@UPDATE_TYPE_NAME = 'GROUP_UPDATE_NAME'
	@UPDATE_TYPE_UNREADAMOUNT = 'GROUP_UPDATE_UNREADAMOUNT'
	@UPDATE_TYPE_MEMBERLIST = 'GROUP_UPDATE_MEMBERLIST'

	@ROLE_USER = 'ROLE_USER'
	@ROLE_MERCHANT = 'ROLE_MERCHANT'

	@GROUP_STATUS_ONLINE = GROUP_STATUS_ONLINE = 'GROUP_STATUS_ONLINE'
	@GROUP_STATUS_OFFLINE = GROUP_STATUS_OFFLINE = 'GROUP_STATUS_OFFLINE'

	defaults:
		additional_name: ''
		created_at: 0
		image:
			id: 0
			url: ''
			url_original: ''
		name: ''
		role: ''
		status: ''
		unread_amount: 0
		updated_at: 0

class Iconto.REST.GroupCollection extends Iconto.REST.WSCollection
	url: 'group'
	model: Iconto.REST.Group

	parse: (data) ->
		switch data.type
			when 'COLLECTION_TYPE_GROUP'
				data.groups or []
			else
				data