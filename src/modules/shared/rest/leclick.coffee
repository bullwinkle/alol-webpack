# ========== /leclick-restaurant ==========
class Iconto.REST.LeclickRestaurant extends Iconto.REST.RESTModel
	constructor: ->
		super
		_.extend @, Backbone.Validation.mixin

	urlRoot: 'leclick-restaurant'
	defaults:
		id: ""
		name: ""
		lat: 0
		lon: 0

	validation:
		name: ""
		lat: 0
		lon: 0

class Iconto.REST.LeclickRestaurantCollection extends Iconto.REST.RESTCollection
	url: 'leclick-restaurant-list'
	model: Iconto.REST.LeclickRestaurant


# ========== /leclick-reserve ==========
class Iconto.REST.LeclickReserve extends Iconto.REST.RESTModel
	@STATUSES = STATUSES =
		"1": "Ожидает подтверждения"
		"2": "Подтверждено"
		"3": "Опаздывает"
		"4": "Отменено"
		"5": "Отменено пользователем"
		"6": "Пришел"
		"7": "Не пришел"
		"8": "В ожидании"
		"9": "В обработке"
		"10": "Подозрение на спам"

	constructor: ->
		super
		_.extend @, Backbone.Validation.mixin

	urlRoot: 'leclick-reserve'
	defaults:
		id: 0
		comment: ""
		created_at: 0
		deleted: false
		leclick_id: 0
		persons: 2
		phone: ""
		restaurant_id: 0
		status: 2
		time_at: 0
		updated_at: 0
		user_id: 0
		user_name: ""

	validation:
		user_name:
			required: true
		phone:
			required: true
			pattern: 'phone'
		persons:
			required: true
			min: 1
			max: 100

	parse: (model, options) =>
		model.status = _.get STATUSES, model.status, model.status
		model

class Iconto.REST.LeclickReserveCollection extends Iconto.REST.RESTCollection
	url: 'leclick-reserve'
	model: Iconto.REST.LeclickReserve

# ========== /leclick-city ==========
class Iconto.REST.LeclickCity extends Iconto.REST.RESTModel
	constructor: ->
		super
		_.extend @, Backbone.Validation.mixin

	urlRoot: 'leclick-city'
	defaults:
		id: ""
		name: ""
		lat: 0
		lon: 0

	validation:
		name: ""
		lat: 0
		lon: 0

class Iconto.REST.LeclickCityCollection extends Iconto.REST.RESTCollection
	url: 'leclick-city'
	model: Iconto.REST.LeclickCity