@Iconto.module 'wallet', (Wallet) ->

	Wallet.controller = new Wallet.Controller()


	Wallet.helperRouter = new Wallet.HelperRouter controller: Wallet.controller

	Wallet.router = new Wallet.Router controller: Wallet.controller