@Iconto.module 'icgy.views', (Icgy) ->
	GENERATOR_URL = '//ic.gy/generate'

	class ShortLinkModel extends Backbone.Model
		defaults:
			url: ''
		validation:
			url:
				pattern: 'url'
	_.extend ShortLinkModel::, Backbone.Validation.mixin

	class Icgy.ShortLinkGeneratorView extends Marionette.ItemView
		className: 'short-link-generator-view'

		template: JST['icgy/templates/short-link-generator']

		behaviors:
			Epoxy: {}

		ui:
			input: 'input'
			form: 'form'
			submit: 'button[type=submit]'
			moreButton: '[name=more]'

		events:
			'submit @ui.form': 'onFormSubmit'

		#		modelEvents:
		#			'validated:valid': ->
		#				@ui.form.removeClass 'has-validation-error'
		#				@ui.submit.removeAttr 'disabled'
		#			'validated:invalid': ->
		#				@ui.form.addClass 'has-validation-error'
		#				@ui.submit.attr 'disabled', true

		initialize: =>
			@model = new ShortLinkModel()

			@listenTo @model, 'change:url', (model, value, options) =>
				if value
					if Backbone.Validation.patterns.url.test(value)
						@ui.form.removeClass 'has-validation-error'
						@ui.submit.removeAttr 'disabled'
					else
						@ui.form.addClass 'has-validation-error'
						@ui.submit.attr 'disabled', true
				else
					@ui.form.removeClass 'has-validation-error'
					@ui.submit.removeAttr 'disabled'

		onRender: =>
			Backbone.Validation.bind @

		onFormSubmit: (e) =>
			e.preventDefault()
			unless @model.isValid()
				Iconto.shared.views.modals.Alert.show
					title: 'Ошибка'
					message: 'Неправильный адрес'
			else
				Q($.post(GENERATOR_URL, url: @model.get('url')))
				.then (response) =>
					if response.status is 0
						Iconto.icgy.views.PromptModal.show
							title: 'Короткая ссылка'
							inputValue: "https:#{response.data.id}"
							valueSelected: true
							submitButtonText: 'Копировать'
					else
						throw new ObjectError response
				.catch (error) =>
					console.error error
					if error.responseJSON
						error = error.responseJSON.data
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()