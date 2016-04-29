class Iconto.REST.Reason extends Iconto.REST.WSModel

	@TYPE_USER = 'REASON_TYPE_USER'
	@TYPE_COMPANY = 'REASON_TYPE_COMPANY'
	@TYPE_REVIEW = 'REASON_TYPE_REVIEW'
	@TYPE_ADDRESS = 'REASON_TYPE_ADDRESS'
	@TYPE_REFERENCE = 'REASON_TYPE_REFERENCE'
	@TYPE_DEPARTMENT = 'REASON_TYPE_DEPARTMENT'
	@TYPE_COMPANY_AGGREGATED = 'REASON_TYPE_COMPANY_AGGREGATED'
	
	defaults:
		type: null
		group_id: ''
		user_id: 0
		company_id: 0
		address_id: 0
		address_reference: ''
		department_id: 0
