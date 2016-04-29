#= require ./Reason

class Iconto.REST.UserGroup extends Iconto.REST.WSModel
	urlRoot: 'user_group'

	@ROLE_MERCHANT = 1
	@ROLE_USER = 2

	defaults:
		name: ''
		reason: null
		role: null
		updated_at: 0
		created_at: 0
		image: null

	serialize: (data) ->
		data.role = data.role.toJSON() if data.role instanceof Iconto.REST.Reason
		data

class Iconto.REST.UserGroupCollection extends Iconto.REST.WSCollection
	url: 'user_group'
	model: Iconto.REST.UserGroup