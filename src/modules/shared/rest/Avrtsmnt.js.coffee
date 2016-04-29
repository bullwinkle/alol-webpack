class Iconto.REST.Advertisement extends Iconto.REST.RESTModel
	urlRoot: 'advrtsmnt'
	defaults:
		hash: ''
		title: ''
		description: ''
		url: ''
		images: []
		company_id: 0

	validation:
		title:
			required: true
			minLength: 3
			maxLength: 250
		description:
			required: true
			maxLength: 1000
		company_id:
			required: true
		images:
			minSize: 1

_.extend Iconto.REST.Advertisement::, Backbone.Validation.mixin

class Iconto.REST.AdvertisementCollection extends Iconto.REST.RESTCollection
	url: 'advrtsmnt'
	model: Iconto.REST.Advertisement