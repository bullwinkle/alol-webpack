class Iconto.REST.CompanySettings extends Iconto.REST.RESTModel
	urlRoot: 'company-settings'

	defaults:
		background_color: ''
		background_image_id: 0
		background_image_url: ''
		background_bubble_color: ''
		background_image_size: 'cover'
		button_color: ''
		company_id: 0
		domain: ''
		text_color: ''
		welcome_text: ''
		origin: 'iconto.net'

	validation:
		domain:
			required: true
			minLength: 2
			maxLength: 20
			pattern: /^[a-zA-Z0-9]{2,32}$/
			msg: 'Допустимы только буквы латинского алфавита и цифры'

_.extend Iconto.REST.CompanySettings::, Backbone.Validation.mixin

class Iconto.REST.CompanySettingsCollection extends Iconto.REST.RESTCollection
	url: 'company-settings'
	model: Iconto.REST.CompanySettings