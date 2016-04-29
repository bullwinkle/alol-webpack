class Iconto.REST.SocialContent extends Iconto.REST.RESTModel
	urlRoot: 'social-content'

#_.extend Iconto.REST.SocialContent::, Backbone.Validation.mixin

class Iconto.REST.SocialContentCollection extends Iconto.REST.RESTCollection
	url: 'social-content'
	model: Iconto.REST.SocialContent