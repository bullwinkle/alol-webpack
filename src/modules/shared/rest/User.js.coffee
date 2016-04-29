class Iconto.REST.User extends Iconto.REST.RESTModel
	urlRoot: 'user'

	@PERSONAL_INFO_STATUS_EMPTY   = PERSONAL_INFO_STATUS_EMPTY   = 0
	@PERSONAL_INFO_STATUS_PENDING = PERSONAL_INFO_STATUS_PENDING = 1
	@PERSONAL_INFO_STATUS_CANCEL  = PERSONAL_INFO_STATUS_CANCEL  = 2
	@PERSONAL_INFO_STATUS_APPROVE = PERSONAL_INFO_STATUS_APPROVE = 3

	@PERSONAL_PHONE_STATUS_EMPTY = PERSONAL_PHONE_STATUS_EMPTY = 0
	@PERSONAL_PHONE_STATUS_APPROVED = PERSONAL_PHONE_STATUS_APPROVED = 3

	@STATUS_UNAUTHORIZED = 200005
	@STATUS_FORBIDDEN = 200002

	defaults:
		id: 0
		nickname: ''
		first_name: ''
		last_name: ''
		email: ''
		phone: ''
		birthday: ''
		sex: 0
		marriage: 0
		image_id: 0
		image:
			id: 0
			url: ''
		personal_phone_status: 0
		personal_info_status: 0
		personal_info_error: ''
		is_offer_accepted: false
		is_email_confirmed: false
		offer_version: 0
		settings:
			notifications:
				accept_untrusted: false #Получать сообщения от неизвестных компаний

	validation:
		first_name:
			required: true
			maxLength: 99
		last_name:
			required: true
			maxLength: 100
		email:
			required: true
			pattern: 'email'
		login:
			required: true
			pattern: 'phone'
		phone:
			required: false
			pattern: 'phone'
		birthday:
			required: false
			maxUnixDate: moment().format('YYYY-MM-DD')

	serialize: (data) ->
		data.phone -= 0 if data.phone
		data

	parse: (data) ->
		data.phone = data.phone || data.login unless _.isEmpty data
		data

_.extend Iconto.REST.User::, Backbone.Validation.mixin

class Iconto.REST.UserCollection extends Iconto.REST.RESTCollection
	url: 'user'
	model: Iconto.REST.User