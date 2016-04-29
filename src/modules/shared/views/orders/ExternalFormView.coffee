Iconto.module 'shared.views.orders', (Orders) ->

	inherit = Iconto.shared.helpers.inherit

	class OrderFormModel extends Backbone.Model
		defaults:
			formPath: 'https://docs.google.com/forms/d/112n06q93KpXpevSaZnR0rEpgG4Edp9h8unTtsx6zc0k/viewform'

	class Orders.ExternalFormView extends Marionette.ItemView
		template: JST['shared/templates/orders/order-form-external']
		className: 'form-view external'

		ui:
			frame: '#form-frame'
			frameWrapper: '.form-frame-container'

		initialize: ->
			@state = new Iconto.shared.models.BaseStateViewModel()
			@model = new OrderFormModel @options

			query = Iconto.shared.helpers.navigation.getQueryParams()
			url = Iconto.shared.helpers.navigation.parseUri(query.path).href
			console.log url


		onRender: =>
			@ui.frameWrapper.addClass 'is-loading'
			@ui.frame.on 'load', =>
				console.log 'form loaded'
				@ui.frameWrapper.removeClass 'is-loading'
				frame = @ui.frame[0]
				contentWindow =  frame.contentWindow
				contentDocument =  frame.contentDocument
				$contentDocument =  $(contentDocument)

				$contentDocument.on 'click', 'a,button,input', -> console.warn arguments

				isTop = contentWindow is window
				console.log 'isTop? ', isTop

				$form = $contentDocument.find('form')
				$submit = $form.find '[name=submit]'

				if $form.attr('action')?.length > 0
					$form.off('submit')
				$form.on 'submit', (e) ->

					submitedObject =
						formData: $form.serializeObject()
					console.log submitedObject

					if iContoBridge?.notify
						iContoBridge.notify 'form-submit',
							data: submitedObject

					else
						alert 'form submit'

					return true