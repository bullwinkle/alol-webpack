#@Iconto.module 'shared.views.modals', (Modals) ->
#
#	class PromptModel extends Backbone.Model
#		defaults:
#			title: ''
#			message: ''
#			type: 'text'
#			placeholder: ''
#			inputText: ''
#			canClose: true
#			buttonText: 'Ok'
#		validation:
#			inputText:
#				required: true
#	_.extend PromptModel::, Backbone.Validation.mixin
#
#	class Modals.OldPrompt extends Marionette.LayoutView
#		className: 'reveal-modal prompt'
#
#		template: JST['templates/modals/prompt']
#
#		attributes:
#			'data-reveal': true
#
#		ui:
#			input: 'input'
#			ok: 'button[name=ok]'
#
#		events:
#			'click button[name=ok]:not(.loading)': 'onOkClick'
#			'click .destroy-reveal-modal': 'onDestroyRevealModalClick'
#			'keyup input': 'onInputKeyUp'
#
#		modelEvents:
#			'validated:valid': 'onModelValid'
#			'validated:invalid': 'onModelInvalid'
#
#		initialize: (options) =>
#			@onOk = options.onOk
#			@onCancel = options.onCancel
#			@onDestroy = options.onDestroy
#			@model = new PromptModel options
#			unless @model.get('canClose')
#				@$el.attr 'data-options', 'destroy_on_background_click: false'
#
#		@show: (options) ->
#			prompt = new Modals.OldPrompt options
#			prompt.show()
#			prompt
#
#		show: =>
#			unless @isShown
#				@render()
#				$('body').append @$el
#				$(document).on "destroy.#{@cid}", '[data-reveal]', (e) =>
#					unless @isDestroyed
#						@trigger 'prompt:destroy'
#						@onDestroy?()
#						if @destroy
#							@destroy()
#						else
#							@remove() if @remove
#
#				$(document).foundation()
#				@$el.foundation('reveal', 'open')
#				@isShown = true
#
#		hide: =>
#			@$el.foundation('reveal', 'destroy')
#
#		onBeforeDestroy: =>
#			$(document).off "destroy.#{@cid}", '[data-reveal]'
#			$(document).off "click.#{@cid}", '.reveal-modal-bg'
#
#		onOkClick: =>
##			console.log 'prompt:ok', @model.get 'inputText'
#			model = @model.toJSON()
#			@onOk?(model.inputText)
#			@trigger "prompt:ok", model.inputText
#
#		onInputKeyUp: =>
#			value = $.trim @ui.input.val()
#			@model.set 'inputText', value, validate: true
#
#		onModelValid: =>
#			@ui.ok.removeAttr 'disabled'
#
#		onModelInvalid: =>
#			@ui.ok.attr 'disabled', true
#
#		onDestroyRevealModalClick: =>
#			@onCancel?()