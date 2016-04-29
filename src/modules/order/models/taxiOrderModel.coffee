Iconto.module 'order.models', (Models) ->

	class Models.TaxiOrderModel extends Iconto.REST.RESTModel
		defaults:
			phone: ""
			fromAddress: ""
			whereAddress: ""
			when_time: ""
			when_date: ""
			car_type: "standart"
			city: ''
			cityId: 0
			comment: ''

		validation:
			phone:
				required: true
				minLength: 7
				maxLength: 200

			fromAddress:
				required: true
				minLength: 3
				maxLength: 200

			whereAddress:
#				required: true
#				minLength: 3
				maxLength: 200

			when_time:
				required: false

			when_date:
				required: false

			car_type:
				required: false

		serealize: (model) =>
			model.from = model.fromAddress
			model.where = model.whereAddress
			delete model.fromAddress
			delete model.whereAddress

	_.extend Models.TaxiOrderModel::,Backbone.Validation.mixin