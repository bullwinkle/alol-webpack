class Iconto.REST.PaymentSystem extends Iconto.REST.RESTModel
	urlRoot: 'payment-system'
	defaults:
		title: ''
		mark: ''
		image_url: ''
		created_at: 0
		deleted: false

class Iconto.REST.PaymentSystemCollection extends Iconto.REST.RESTCollection
	url: 'payment-system'
	model: Iconto.REST.PaymentSystem