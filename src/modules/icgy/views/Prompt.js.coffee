@Iconto.module 'icgy.views', (Icgy) ->
	class PromptModel extends Backbone.Model
		defaults:
			title: ''
			message: ''
			submitButtonText: 'ОК'
			cancelButtonText: 'Отмена'
			valueSelected: false
			type: 'text'
			input: ''

	class Icgy.PromptModal extends Backbone.Modal

		handlerMap =
			onCancel: 'cancel'
			onBeforeCancel: 'beforeCancel'
			onSubmit: 'submit'
			onBeforeSubmit: 'beforeSubmit'

		className: 'prompt'

		template: JST['icgy/templates/icgy-prompt']

		cancelEl: '[name=cancel]'
		submitEl: '[name=ok]'

		constructor: (options) ->
			super
			@[handler] = options[event] for event, handler of handlerMap when options[event]

		initialize: (options) =>
			@model = new PromptModel(options)

		show: =>
			Iconto.commands.execute 'modals:show', @

		onRender: =>
			@$('input').on 'mousedown', @onFocus

		onFocus: (e) =>
			e.currentTarget.setSelectionRange 0, e.currentTarget.value.length
			false

		close: =>
			super
			@$('input').off 'input.prompt paste.prompt change.prompt', @onInput

		@show: (options) =>
			prompt = new Icgy.PromptModal options
			prompt.show()
			if options.valueSelected
				$answerInput = prompt.$el.find('input.answer-input')
				$answerInput.prop 'readonly', true
				$answerInput.prop 'autofocus', true
				answerInput = $answerInput[0]
				answerInput.setSelectionRange 0, answerInput.value.length
			prompt

			# TODO: @clipboard.destroy()
			@clipboard = new Clipboard 'button[name=ok]',
				text: -> options.inputValue
			@clipboard.on 'success', (e) ->
				console.log(e)
			@clipboard.on 'error', (e) ->
				console.log(e)