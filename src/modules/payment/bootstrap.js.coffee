@Iconto.module 'payment', (Payment) ->

	Payment.router = new Payment.Router controller: new Payment.Controller()