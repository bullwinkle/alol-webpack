#= require ./FormBehavior

@Iconto.module 'shared.behaviors', (Behaviors) ->
	class Behaviors.EditableForm extends Behaviors.Form

		defaults: _.extend({}, Behaviors.Form::defaults,
			preload: 'preload'
		)

		onRender: =>
			super
			submit = @options.submit
			@view.$(submit).prop('disabled', true) if submit
			Q.fcall =>
				@view[@options.preload]?.call @view
			.done =>
				if submit
					for key, source of @sources
						@view.listenTo source, 'change', =>
							@view.$(submit).prop('disabled', false)