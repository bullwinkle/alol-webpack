class Iconto.REST.AddressSpotReview extends Iconto.REST.RESTModel
	urlRoot: 'address-spot-review'
	defaults:
		id: 0
		hash: ''
		review: ''
		is_public: false

#_.extend Iconto.REST.AddressReview::, Backbone.Validation.mixin

class Iconto.REST.AddressSpotReviewCollection extends Iconto.REST.RESTCollection
	url: 'address-spot-review'
	model: Iconto.REST.AddressSpotReview