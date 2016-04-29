@Iconto.module 'office.models', (Models) ->
	
	class Models.StateViewModel extends Iconto.shared.models.BaseStateViewModel

	_.extend Models.StateViewModel::defaults,
		companyId: 0