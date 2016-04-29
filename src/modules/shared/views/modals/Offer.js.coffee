#= require ./BaseModal
@Iconto.module 'shared.views.modals', (Modals) ->

	class OfferModel extends Modals.BaseModel
		defaults:
			documentUrl: '/'                        # относительная ссылка на документ, который покажется в iframe модальника
			isSubmitBlockedUnlessScrolled: false    # должна ли кнопка принять быть заблокированной, пока документ не доскроллен до конца
			offerType: 0                            # номер типа оферты, хранятся в Iconto.REST.Offer
			submitButtonText: 'Принимаю'
			cancelButtonText: 'Не принимаю'


	class Modals.Offer extends Modals.BaseModal
		madalName: 'offer'
		className: 'offer'

		template: JST['shared/templates/modals/offer']

		cancelEl: '[name=cancel]'
		submitEl: '[name=ok]'

		ui: {}

		initialize: (options) =>
			@model = new OfferModel options
			@offerType = @model.get 'offerType'

		# off closing modal by clicking outside and by tapping escape, call onCancel handler from options
		triggerCancel: =>
			@cancel()

		onShow: =>
			@ui.submitEl = @$el.find(@submitEl)
			@ui.cancelEl = @$el.find(@cancelEl)

			$documentFrame = @$el.find('#doc')

			if @model.get 'isSubmitBlockedUnlessScrolled' # able submit button just when all document scrolled or visible on load
				@ui.submitEl.prop 'disabled', true
				$documentFrame.load =>
					$($documentFrame[0].contentDocument).ready =>

						defer = =>
							docWindow = $documentFrame[0].contentWindow
							docDocument = $documentFrame[0].contentDocument
							docBody = docDocument.body

							if $(docWindow).outerHeight() >= $(docBody).outerHeight() - 50
								@ui.submitEl.prop 'disabled', false
							else
								$(docWindow).on 'scroll', (e) =>
									currentScrollTop = (docDocument.documentElement and docDocument.documentElement.scrollTop) or docDocument.body.scrollTop
									if currentScrollTop >= $(docBody).outerHeight() - $(docWindow).outerHeight() - 50
										@ui.submitEl.prop 'disabled', false
								$(docWindow).trigger 'scroll'

						setTimeout defer, 500 # this is really need for IE

			$documentFrame.attr 'src', "#{ @model.get 'documentUrl' }"

		@show: (options) =>
			offer = new Modals.Offer options
			offer.show()
			offer