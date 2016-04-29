class Iconto.REST.CompanyReview extends Iconto.REST.RESTModel
	urlRoot: 'company-review'
	version: '3.0'

	@TYPE_SMILE = 1
	@TYPE_SAD = 2
	@TYPE_IDEA = 3

	@STATUS_OPEN = 1
	@STATUS_CLOSE = 2
	@STATUS_RESOLVED = 3

	@RATING_NONE = 1
	@RATING_NEGATIVE = 2
	@RATING_POSITIVE = 3

	defaults:
		user_id: 0
		user_phone: ''
		company_id: 0
		type: @TYPE_SMILE
		status: @STATUS_OPEN
		rating: @RATING_NONE
		message: ''
		image_ids: []

	validation:
		user_phone:
			required: true
			pattern: 'phone'

_.extend Iconto.REST.CompanyReview::, Backbone.Validation.mixin

class Iconto.REST.CompanyReviewCollection extends Iconto.REST.RESTCollection
	url: 'company-review'
	model: Iconto.REST.CompanyReview