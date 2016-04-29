class Iconto.REST.UserGroupLink extends Iconto.REST.WSModel
	urlRoot: 'user_group_link'
	defaults:
		group_id: ''
		user_id: ''

class Iconto.REST.UserGroupLinkCollection extends Iconto.REST.WSCollection
	url: 'user_group_link'
	model: Iconto.REST.UserGroupLink