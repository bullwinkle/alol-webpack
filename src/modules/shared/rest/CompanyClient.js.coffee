class Iconto.REST.CompanyClient extends Iconto.REST.RESTModel

	@SOURCE_TYPE_UNKNOWN      = SOURCE_TYPE_UNKNOWN     = 0
	@SOURCE_TYPE_MANUAL       = SOURCE_TYPE_MANUAL      = 1 #show first_name and last_name
	@SOURCE_TYPE_FILE         = SOURCE_TYPE_FILE        = 2 # -//-
	@SOURCE_TYPE_TRANSACTION  = SOURCE_TYPE_TRANSACTION = 3 #show only nickname
	@SOURCE_TYPE_CHAT         = SOURCE_TYPE_CHAT        = 4 # -//-

	@FILTER_ALL = 'all'
	@FILTER_VIP = 'vip'
	@FILTER_NONVIP = 'nonvip'
	@FILTER_CUSTOM = 'custom'

	urlRoot: 'company-client'
	defaults:
		first_name: ''
		first_name_display: ''
		first_name_orig: ""
		last_name: ''
		last_name_display: ''
		last_name_orig: ''
		nickname: ''
		user_id: 0
		external_id: ''
		phone: ''
		email: ''
		sex: 0
		company_id: 0
		birthday: ''
		is_vip: false
		description: ''
		source_type: @SOURCE_TYPE_UNKNOWN
		image:
			url: ''
		address_ids: []
		address_id: 0
		balance: "0.00"
		buy_amount: "0.00"
		buy_count: 0
		card_name: ""
		cashback_amount: "0.00"
		cashback_count: 0
		created_at: 0
		currency_name: ""
		deleted: false
		deleted_at: 0
		discount_amount: "0.00"
		discount_count: 0
		discount_percent: 0
		expired_at: 0
		group_character: ""
		is_dotpay: 0
		first_buy_at: 0
		last_buy_at: 0
		last_buy_amount: "0.00"
		updated_at: 0

	validation:
		first_name:
			required: false
			maxLength: 99
		last_name:
			required: false
			maxLength: 100
		phone:
			required: true
			pattern: 'phone'
		email:
			required: false
			pattern: 'email'
			maxLength: 64
		birthday:
			required: false
			pattern: /^\d{4}-\d{2}-\d{2}$/
			maxUnixDate: moment().format('YYYY-MM-DD')
		external_id:
			required: false
			pattern: 'digits'
			msg: 'Код может содержать только цифры'

	getName: =>
		firstName = @get('first_name_display')
		lastName = @get('last_name_display')
		nickName = @get('nickname')
		id = @get('id')
		user_id = @get('user_id')

		if firstName or lastName
			"#{firstName} #{lastName}"
		else if nickName
			"#{nickName}"
		else
			"Аноним ##{user_id}"

_.extend Iconto.REST.CompanyClient::, Backbone.Validation.mixin

class Iconto.REST.CompanyClientCollection extends Iconto.REST.RESTCollection
	url: 'company-client'
	model: Iconto.REST.CompanyClient

	destroyAll: (data) =>
		key = _.result(@, 'url')
		_.extend data, all: true
		@sync('delete', @, data: data)
		.then (response) =>
			Iconto.REST.cache[key] = {} #FIXME!!!
			response
