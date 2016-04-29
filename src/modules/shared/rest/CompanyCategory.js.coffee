class Iconto.REST.CompanyCategory extends Iconto.REST.RESTModel
	urlRoot: 'company-category'
	defaults:
		id: 0
		parent_id: 0
		name: ''
		icon_url: ''
		created_at: 0
		deleted: false

class Iconto.REST.CompanyCategoryCollection extends Iconto.REST.RESTCollection
	url: 'company-category'
	model: Iconto.REST.CompanyCategory