@Iconto.module 'shared.views.wizard', (Wizard) ->

	class Wizard.BaseWizardLayout extends Marionette.LayoutView
		className: 'base-wizard-layout'

		#place config for WizardRegion here or pass to contructor

		template: -> '<div name="wizard-region" role="region"></div>'

		ui:
			wizardRegion: '[name=wizard-region]'

		constructor: ->
			super
			@on 'render', =>
				config = Marionette.getOption @, 'config'
				wizard = new Wizard.WizardRegion
					el: @ui.wizardRegion
					config: config

				@addRegion 'wizardRegion', wizard

		transition: =>
			@wizardRegion.transition.apply @, arguments