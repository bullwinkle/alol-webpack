class Iconto.REST.Company extends Iconto.REST.RESTModel

	@SHOP_STATUS_AUTO = SHOP_STATUS_AUTO = 0 # статус по умолчанию (выключен, при добавлении первого товара автоматически включится)
	@SHOP_STATUS_DISABLED = SHOP_STATUS_DISABLED = 1 # выключен (принудительно)
	@SHOP_STATUS_ENABLED_INTERNAL = SHOP_STATUS_ENABLED_INTERNAL = 2 # включен внутренний магазин
	@SHOP_STATUS_ENABLED_EXTERNAL = SHOP_STATUS_ENABLED_EXTERNAL = 3 # включен внешний магазин (который прописан в order_form_url)

	@TAXI_FORM_PATH = '/wallet/services/taxi'

	@ALIAS_ULMART = 'ulmart'
	@ALIAS_RYADY = 'ryady'

	@MAIN_COMPANY_IDS = MAIN_COMPANY_IDS = # taken from ios
		icontoTeam: [2775, 2775, 2775]
		taxi: [7324, 5451, 5451]
		restaurantBooking: [7321, 5458, 5452]
		beautySalon: [7328, 5459, 5453]
		flowersDelivery: [10018, 5462, 5462]
		supermarket: [10578, 5463, 5457]
		foodDelivery: [9, 9, 9]
		leclick: [8142, 8142, 8142]

	apiUrl = window.ICONTO_API_URL
	env = if apiUrl?.indexOf('dev') >= 0 then 'dev' else if apiUrl.indexOf('stage') >= 0 then 'stage' else 'prod'
	@mapDomainToCompanyIds = (ids) => # taken from ios
		if !_.isArray(ids)
			console.error 'mapToDomain expects array with 3 numbers in it'
		switch env
			when 'dev'
				ids[1]
			when 'stage'
				ids[2]
			when 'prod'
				ids[0]
			else
				ids[0]

	@checkCompanyIfMain = (id) =>
		id += 0
		result = false
		_.each @MAIN_COMPANY_IDS, (val, key) =>
			if id is @mapDomainToCompanyIds val
				result = key
		result

	urlRoot: 'company'
	defaults:
		account_id: 0
		category_id: 0
	#		acquirer_id: 0
		alias: ''
	#		category_id: 0
	#		company_type: 0
	#		contact_email: ''
	#		contact_name: ''
	#		contract_date: 0
	#		contract_num: ''
		country_id: 0
		created_at: 0
		deleted: false
		deleted_at: 0
		description: ''
		domain: ''
		email: ''
		brand_id: 0
		legal_id: 0
		id: 0
		image_id: 0
		image_url: ''
		is_active: 0
		is_real_contract: false
		name: ''
		phone: ''
		sender_name: ''
		tags: ''
		welcome_message: ''
		greeting_message: ''
		address_count: 0
		site: ''
		image:
			url: ''
		facebook_id: ''
		has_shop: false
		rules_type: 'url'
		rules_text: ""
		rules_url: ""

		sms_notify_users: false

		settings:
			notifications:
			#				sms_delay: 0 #Отправлять SMS, если сообщение в мессенджере не прочитано более delay секунд
				sms_delay: 3600 #Отправлять сообщение через SMS, если пользователь не прочел сообщение в мессенджере втечение часа
				sms_delivery: true #Отправлять через SMS, если невозможно доставить сообщение в мессенджер
				sms_schedule: true #Отправлять SMS, если сообщение в мессенджере не прочитано

		shop_order_min_amount: 0
		shop_order_threshold_amount: 0
		shop_order_delivery_amount: 0
		shop_order_delivery_discount_amount: 0
		order_form_type: 0
		order_form_url: ''

	#/(http:\/\/|ftp:\/\/|https:\/\/)*[\w-]+(\.[\w-]+)+([\w.,@?^=%&amp;:\/~+#-]*[\w@?^=%&amp;\/~+#-])?/

	validation: ->
		name:
			required: true
			minLength: 2
		email:
			required: true
			pattern: 'email'
		site:
			required: false
			pattern: /^((http|https):\/\/)?[a-zа-я0-9]+([\-\.]{1}[a-zа-я0-9]+)*\.[a-zа-я]{2,5}(:[0-9]{1,5})?(\/.*)?$/

		description:
			maxLength: 2048

		sender_name:
			required: false
			maxLength: 11
			minLength: 2
		domain:
			required: false
			minLength: 2
			maxLength: 20
			pattern: /^[a-zA-Z0-9]{2,32}$/
		category_id:
			required: true
			min: 1
			msg: 'Выберите категорию'
		tags: (value) ->
			if value and value.split(',').length > 100
				'Максимальное количество тегов - 100.'
		shop_order_min_amount:
			required: true
			min: 0
			max: 999999999
			pattern: 'number'
		shop_order_threshold_amount:
			required: true
			min: 0
			max: 999999999
			pattern: 'number'
		shop_order_delivery_amount:
			required: true
			min: 0
			max: 999999999
			pattern: 'number'
		shop_order_delivery_discount_amount:
			required: true
			min: 0
			max: 999999999
			pattern: 'number'
		order_form_url:
			if @get('order_form_type') is SHOP_STATUS_ENABLED_EXTERNAL
				required: true
				minLength: 3
		rules_url:
			if @get('rules_type') is 'url'
				required: false
				minLength: 5
			else
				minLength: 0

	serialize: (obj) =>
		delete obj.rules_type # needed just for binding
		obj

_.extend Iconto.REST.Company::, Backbone.Validation.mixin

class Iconto.REST.CompanyCollection extends Iconto.REST.RESTCollection
	url: 'company'
	model: Iconto.REST.Company