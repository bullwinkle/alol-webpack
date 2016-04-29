class Iconto.REST.LegalEntity extends Iconto.REST.RESTModel
	@LEGAL_TYPE_OOO = LEGAL_TYPE_OOO = 1
	@LEGAL_TYPE_OAO = LEGAL_TYPE_OAO = 2
	@LEGAL_TYPE_IP = LEGAL_TYPE_IP = 3
	@LEGAL_TYPE_ZAO = LEGAL_TYPE_ZAO = 4

	@LEGAL_TYPES = LEGAL_TYPES = ['ООО', 'ОАО', 'ИП', 'ЗАО']

	urlRoot: 'legal-entity'
	defaults:
		name: ''
		inn: ''
		account_check: ''
		company_id: 0
		cor_check: ''
		kpp: ''
		ogrn: ''
		type: 1
		country_id: 0
		city_id: 0
		address: ''
		deposit_id: 0

	validation: ->
		name:
			required: true
			minLength: 3
		inn:
			required: true
			pattern: 'digits'
			length: if @get('type') is LEGAL_TYPE_IP then 12 else 10
			inn: true
		ogrn:
			required: false
			pattern: 'digits'
			length: if @get('type') is LEGAL_TYPE_IP then 15 else 13
			ogrn: true
		account_check:
			required: false
			pattern: 'digits'
			length: 20
		cor_check:
			required: false
			pattern: 'digits'
			length: 20
		kpp:
			required: false
			pattern: 'digits'
			length: 9

		country_id:
			required: true
			min: 1
			msg: 'Выберите страну'

		city_id:
			required: true
			min: 1
			msg: 'Выберите город'

		address:
			required: true
			minLength: 3
			msg: 'Введите адрес'

_.extend Iconto.REST.LegalEntity::, Backbone.Validation.mixin

class Iconto.REST.LegalEntityCollection extends Iconto.REST.RESTCollection
	url: 'legal-entity'
	model: Iconto.REST.LegalEntity