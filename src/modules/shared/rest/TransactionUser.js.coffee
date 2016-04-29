class Iconto.REST.TransactionUser extends Iconto.REST.RESTModel
	urlRoot: 'transaction-user'

	defaults:
		amount: 0

class Iconto.REST.TransactionUserCollection extends Iconto.REST.RESTCollection
	url: 'transaction-user'