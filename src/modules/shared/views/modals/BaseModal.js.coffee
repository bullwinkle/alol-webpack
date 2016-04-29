@Iconto.module 'shared.views.modals', (Modals) ->

	class Modals.BaseModel extends Backbone.Model
		defaults:
			title: ''
			message: ''
			submitButtonText: 'ОК'
			cancelButtonText: 'Отмена'

	class Modals.BaseModal extends Backbone.Modal

		handlerMap =
			onCancel: 'cancel'
			onBeforeCancel: 'beforeCancel'
			onSubmit: 'submit'
			onBeforeSubmit: 'beforeSubmit'

		constructor: (options) ->
			super
			if options
				@[handler] = options[event] for event, handler of handlerMap when options[event]

		show: =>
			Iconto.commands.execute 'modals:show', @

		checkKey: (e) =>
			if @active
				switch e.keyCode
					when 27 then @triggerCancel()
#					when 13
#						if @submit
#							@triggerSubmit()
#						else
#							@triggerCancel()