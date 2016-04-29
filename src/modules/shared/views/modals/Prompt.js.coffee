#= require ./BaseModal

@Iconto.module 'shared.views.modals', (Modals) ->

	class PromptModel extends Modals.BaseModel
	_.extend PromptModel::defaults,
		input: ''
		type: 'text'
		value: ''

	class Modals.Prompt extends Modals.BaseModal
		className: 'prompt'

		template: JST['shared/templates/modals/prompt']

		cancelEl: '[name=cancel]'
		submitEl: '[name=ok]'
		inputEl: '[name=input]'

		initialize: (options) =>
			@model = new PromptModel(options)

		onRender: =>
			@$('input').on 'input.prompt paste.prompt change.prompt', @onInput
			@errorMessageEl = @$('.error-message').eq(0)

		destroy: =>
			super
			@$('input').off 'input.prompt paste.prompt change.prompt', @onInput

		@show: (options) =>
			prompt = new Modals.Prompt options
			prompt.show()
			prompt

		onInput: (e) =>
			@errorMessageEl.text ''
			value = $(e.currentTarget).val()
			@model.set 'input', value, validate: true
			true
