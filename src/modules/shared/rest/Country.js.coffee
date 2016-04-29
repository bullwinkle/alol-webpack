class Iconto.REST.Country extends Iconto.REST.RESTModel
	urlRoot: 'country'
	defaults:
		name: ''

class Iconto.REST.CountryCollection extends Iconto.REST.RESTCollection
	url: 'country'
	model: Iconto.REST.Country