class Iconto.REST.ProviderCategory extends Iconto.REST.RESTModel
	urlRoot: 'provider-category'
	defaults:
		name: ""
		external_id: 1144
		external_type: 1

class Iconto.REST.ProviderCategoryCollection extends Iconto.REST.RESTCollection
	url: 'provider-category'
	model: Iconto.REST.ProviderCategory