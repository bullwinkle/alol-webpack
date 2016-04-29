class Iconto.REST.Brand extends Iconto.REST.RESTModel
	urlRoot: 'brand'
	defaults:
		id: 0
		name: ''

class Iconto.REST.BrandCollection extends Iconto.REST.RESTCollection
	url: 'brand'
	model: Iconto.REST.Brand