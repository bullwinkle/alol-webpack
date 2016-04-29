#= require ./Task

class Iconto.REST.Order extends Iconto.REST.Task #inherit 'startPolling' method
	urlRoot: 'order'

	@STATUS_UNKNOWN     = Iconto.REST.Task.STATUS_UNKNOWN
	@STATUS_PENDING     = Iconto.REST.Task.STATUS_PENDING
	@STATUS_PROCESSING  = Iconto.REST.Task.STATUS_PROCESSING
	@STATUS_READY       = 'ready'
	@STATUS_COMPLETED   = Iconto.REST.Task.STATUS_COMPLETED
	@STATUS_ERROR       = Iconto.REST.Task.STATUS_ERROR
	@STATUS_TIMEOUT     = Iconto.REST.Task.STATUS_TIMEOUT

	@TYPE_UNKNOWN = 0
	@TYPE_CARD_REGISTRATION                   = 1 #Платеж при добавлении банковской карты
	@TYPE_CASHBACK_PURCHASE                   = 2 #Платеж за платный cashback
	@TYPE_MONETA_WALLET_COMMITMENT            = 3 #Пополнение кошелька АЛОЛЬ
	@TYPE_CARD2CARD_TRANSFER                  = 4 #Платеж для перевода с карты на карту
	@TYPE_CASHBACK_PAYOUT                     = 5 #Выплата кэшбэка
	@TYPE_TEST_PURCHASE                       = 6 #Покупка всего(для тестов)
	@TYPE_COMPANY_DEPOSIT_COMMITMENT          = 7 #Пополнение депозита компании
	@TYPE_COMPANY_DEPOSIT_COMMITMENT_OFFLINE  = 8 #Пополнение депозита компании через бухгалтерию
	@TYPE_CARD_VERIFICATION                   = 9 #Подтверждение банковской карты

	@TYPE_MONETA_TRANSFER					= 11 #Перевод с монеты на номер телефона
	@TYPE_MONETA_PROVIDER_PAYMENT			= 13 #Оплата поставщиков услуг с кошелька монеты
	@TYPE_MONETA_CARD_PAYMENT 				= 14 #Оплата картой через монеты
	@TYPE_MONETA_WALLET_PAYMENT 			= 15 #Оплата через кошелек монеты


	defaults:
		description: ''
		type: @TYPE_UNKNOWN
		redirect_url: ''
		error_redirect_url: ''
		status: @STATUS_UNKNOWN
		amount: 0
		fee: 0
		fee_amount: 0

	validation:
		amount:
			required: true
			pattern: 'number'
			min: 0
			max: 10000
		type:
			required: true

	serialize: (data) =>
		#cast to int
		for key in ['amount']
			data[key] = data[key] - 0 unless _.isUndefined data[key]
		data

_.extend Iconto.REST.Order::, Backbone.Validation.mixin


