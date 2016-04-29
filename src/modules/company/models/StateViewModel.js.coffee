@Iconto.module 'company.models', (Models) ->
	
	class Models.StateViewModel extends Iconto.shared.models.BaseStateViewModel

	_.extend Models.StateViewModel::defaults,
		addressId: 0
		companyId: 0
