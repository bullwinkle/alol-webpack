class Iconto.REST.Delivery extends Iconto.REST.RESTModel

	@STATUS_PENDING = 'pending'
	@STATUS_RUNNING = 'running'
	@STATUS_COMPLETED = 'completed'
	@STATUS_ERROR = 'error'

	urlRoot: 'delivery'

	defaults:
		company_id: 0
		address_id: 0
		title: ''
		message: ''
		sms_use: false
#		sms_delay: false
		sms_parts_count: 0
		sms_total_count: 0
		sms_total_price: 0
		sms_part_price: 0
		status: @STATUS_PENDING

		chat_read_count: 0
		users_count: 0

		created_at: 0
		updated_at: 0

		customer_filter_is_vip: undefined
		customer_filter_ids: []

	getStatusText: ->
		switch @get('status')
			when Delivery.STATUS_RUNNING
				'Выполняется'
			when Delivery.STATUS_PENDING
				'Ожидает подтверждения'
			when Delivery.STATUS_COMPLETED
				'Завершена'
			when Delivery.STATUS_ERROR
				'Ошибка'

	getStatusIcon: ->
		switch @get('status')
			when Delivery.STATUS_RUNNING
				'ic-gear'
			when Delivery.STATUS_PENDING
				'ic-clock'
			when Delivery.STATUS_COMPLETED
				'ic-check-circle'
			when Delivery.STATUS_ERROR
				'ic-cross-circle'

	getStatusColor: ->
		switch @get('status')
			when Delivery.STATUS_RUNNING, Delivery.STATUS_PENDING
				statusColor = 'yellow'
			when Delivery.STATUS_COMPLETED
				statusColor = 'green'
			when Delivery.STATUS_ERROR
				statusColor = 'red'

	validation:
		title:
			required: true
		message:
			required: true
#		filter:
#			required: true
#			oneOf: [@FILTER_ALL, @FILTER_VIP, @FILTER_NONVIP, @FILTER_CUSTOM]

	serialize: (data) =>
		if _.isUndefined data.customer_filter_is_vip
			delete data.customer_filter_is_vip
		if _.isEmpty data.customer_filter_ids
			delete data.customer_filter_ids
		delete data[key] for key in ['sms_parts_count', 'sms_total_count', 'sms_total_price', 'created_at', 'updated_at']
		data


_.extend Iconto.REST.Delivery::, Backbone.Validation.mixin

class Iconto.REST.DeliveryCollection extends Iconto.REST.RESTCollection
	url: 'delivery'
	model: Iconto.REST.Delivery