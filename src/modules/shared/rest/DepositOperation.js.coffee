class Iconto.REST.DepositOperation extends Iconto.REST.RESTModel

	@TYPE_UNKNOWN = 0
	@TYPE_ADD     = 1
	@TYPE_DEBIT   = 2
	@TYPE_HOLD    = 3

	@PURCHASE_TYPE_UNKNOWN      = 0
	@PURCHASE_TYPE_SMS          = 1
	@PURCHASE_TYPE_CASHBACK     = 2
	@PURCHASE_TYPE_COMMITMENT   = 3
	@PURCHASE_TYPE_DELIVERY     = 4

	@STATUS_UNKNOWN = 0;
	@STATUS_HOLD    = 1;
	@STATUS_DEBIT   = 2;
	@STATUS_UNHOLD  = 3;

	urlRoot: 'deposit-operation'
	defaults:
		amount: 0
		deposit_id: 0
		purchase_description: ''
		purchase_id: 0
		purchase_type: @PURCHASE_TYPE_UNKNOWN
		status: @STATUS_UNKNOWN
		time: 0
		type: @TYPE_UNKNOWN

class Iconto.REST.DepositOperationCollection extends Iconto.REST.RESTCollection
	url: 'deposit-operation'
	model: Iconto.REST.DepositOperation