@Iconto.module 'wallet.views.money', (Money) ->
	class Money.CashbackWithdrawWizardLayout extends Iconto.shared.views.wizard.BaseWizardLayout
		className: 'cashback-withdraw-wizard-layout'

		config: =>
			root: 'cardSelect'
			views:
				cardSelect:
					viewClass: Money.CashbackWithdrawDestinationSelectView
					args: =>
						_.extend view: @, @options
					transitions:
						withdraw: 'withdraw'

				withdraw:
					viewClass: Money.CashbackWithdrawView
					args: =>
						_.extend @model.toJSON(), @options
					transitions:
						destinationSelect: 'destinationSelect'

		initialize: =>
			@model = new Backbone.Model()

			# redirect to cards if status isnt approved
#			unless @options.user.personal_info_status is Iconto.REST.User.PERSONAL_INFO_STATUS_APPROVE
#				Iconto.wallet.router.navigate "/wallet/money", trigger: true, replace: true