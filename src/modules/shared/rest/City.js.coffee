class Iconto.REST.City extends Iconto.REST.RESTModel
	urlRoot: 'city'
	defaults:
		name: ''

class Iconto.REST.CityCollection extends Iconto.REST.RESTCollection
	url: 'city'
	model: Iconto.REST.City