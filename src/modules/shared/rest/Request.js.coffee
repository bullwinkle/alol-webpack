class Iconto.REST.Request extends Iconto.REST.RESTModel
	urlRoot: 'request'
	defaults:
		id: 0
		author_id: 0
#	  completed, reject, error, processing, pending
		status: "pending"
		deleted: false
		updated_at: 0
		created_at: 0
		reason: ''


class Iconto.REST.RequestCollection extends Iconto.REST.RESTCollection
	url: 'request'
	model: Iconto.REST.Request