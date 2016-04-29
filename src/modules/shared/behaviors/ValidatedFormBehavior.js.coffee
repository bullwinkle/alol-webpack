@Iconto.module 'shared.behaviors', (Behaviors) ->

	class Behaviors.ValidatedForm extends Marionette.Behavior
		defaults:
			showLoading: true
			preventSubmit: true
			hideFirstValidation: true

		events:
			'submit form': 'onFormSubmit'
			'submit': 'onFormSubmit' #if current view is a form itself

		modelEvents:
			'validated:valid': 'onModelValid'
			'validated:invalid': 'onModelInvalid'

		onModelValid: ->
			@$('button[type=submit]').removeAttr 'disabled'

		onModelInvalid: ->
			@$('button[type=submit]').attr 'disabled', true

		onRender: =>
			if @options.hideFirstValidation
				if @view.$el.is('form')
					$form = @view.$el
				else
					$form = @view.$('form')
				unless $form.hasClass('hide-validation-errors')
					$form.addClass 'hide-validation-errors'
					$form.delegate 'input, textarea', 'focusin.first-validation', (e) =>
						$form.removeClass 'hide-validation-errors'
						$form.undelegate 'input', 'focusin.first-validation'
			Backbone.Validation.bind @view

		onFormSubmit: (e) ->
			if @options.preventSubmit
				e.preventDefault()

		onValidatedFormUpdate: (data) ->
			#TODO: refactoring
			if data.field
				field = data.field.split('.')[1]
				temp = {}
				temp[field] = 'INVLID DATA ' + field
				@view.model.trigger 'validated:invalid', @view.model, temp
				Backbone.Validation.callbacks.invalid.call @view, @view, field, temp[field], 'name'