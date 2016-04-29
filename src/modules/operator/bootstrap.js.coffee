@Iconto.module 'operator', (Operator) ->
	Operator.controller = new Operator.Controller()
	Operator.router = new Operator.Router controller: Operator.controller