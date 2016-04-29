class Iconto.REST.Provider extends Iconto.REST.RESTModel
	urlRoot: 'provider'
	defaults:
		provider_id: "",
		target_account_id: 0,
		sub_provider_id: 0,
		name: "",
		fields: [ ],
		category_id: 0

class Iconto.REST.ProviderCollection extends Iconto.REST.RESTCollection
	url: 'provider'
	model: Iconto.REST.Provider