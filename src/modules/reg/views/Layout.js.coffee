#= require ./Factory

@Iconto.module 'reg.views', (Views) ->

	# class LayoutViewModel extends Backbone.Epoxy.Model
	# 	defaults:

	class Views.Layout extends Marionette.LayoutView
		className: 'iconto-reg-layout'
		template: JST['reg/templates/layout']

		behaviors:
			Epoxy: {}

		bindings: {}

		bindingSources: ->
			# viewModel: @viewModel
			state: @state

		initialize: =>
			# @viewModel = new LayoutViewModel
			@state = new Iconto.reg.models.StateViewModel @options
			@state.set
				topbarLeftButtonClass: ''
				topbarLeftButtonSpanClass: 'ic-chevron-left'
			@state.on 'change', @update

			@addRegions
				mainRegion: '#reg-main-region'

		onRender: =>

			@update()

		update: =>
			state = @state.toJSON()
			ViewClass = Views.factory(state)
			if @mainRegion
				@mainRegion.show new ViewClass(state)
			else
				console.error 'mainRegion is not defined'
