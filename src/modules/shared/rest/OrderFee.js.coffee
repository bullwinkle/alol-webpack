class Iconto.REST.OrderFee extends Iconto.REST.RESTModel
	urlRoot: 'order-fee'

	@TYPE_CARD_ADD                = TYPE_CARD_ADD                = 1 # Платеж при добавлении банковской карты
	@TYPE_PAID_CASHBACK           = TYPE_PAID_CASHBACK           = 2 # Платеж за платный cashback
	@TYPE_MONETA                  = TYPE_MONETA                  = 3 # Пополнение кошелька АЛОЛЬ
	@TYPE_PAID_TRANSFER           = TYPE_PAID_TRANSFER           = 4 # Платеж для перевода с карты на карту
	@TYPE_CASHBACK                = TYPE_CASHBACK_WITHDRAW       = 5 # Выплата кэшбэка
	@TYPE_ANYTHING                = TYPE_ANYTHING                = 6 # Покупка всего(для тестов)
	@TYPE_DEPOSIT_COMPANY         = TYPE_DEPOSIT_COMPANY         = 7 # Пополнение депозита компании
	@TYPE_DEPOSIT_COMPANY_OFFLINE = TYPE_DEPOSIT_COMPANY_OFFLINE = 8 # Пополнение депозита компании через бухгалтерию

	defaults:
		fee_percent: 0
		minimum_fee: 0
		total: 0
		min_amount: 0
		max_amount: 0

_.extend Iconto.REST.OrderFee::, Backbone.Validation.mixin

class Iconto.REST.OrderFeeCollection extends Iconto.REST.RESTCollection
	url: 'order-fee'
	model: Iconto.REST.OrderFee