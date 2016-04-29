#= require ./template

@Iconto.module 'shared.components', (Components) ->

	###
		container class is 'rating'
		active star class is 'rating-active'

		triggers:
			"change" (value, component) - emits when value has changed
			"click"  (value, component) - emits when value has changed

		possible options are:
		readOnly: true || false
		mod: '' - css class, which will be added to default 'rating'
	###
	class RatingVm extends Backbone.Model
		defaults:
			value: 0

	class Components.Rating extends Marionette.ItemView
		template: JST['shared/components/rating/template']
		className: ->
			className = "rating"
			if @options.mod
				className = "#{className} #{@options.mod}"
			className

		attributes: ->
			_.extend {}, _.pick @options, [
				'readOnly'
			]

		ui:
			stars: "span"

		events:
			"click @ui.stars": "onStarsClick"

		modelEvents:
			'change:value': 'onValueChange'

		initialize: ->
			@model = new RatingVm()

		onRender: =>
			if @options.value
				@model.set 'value', @options.value

		onValueChange: (model,value=0,options) =>
			value = Math.round( (value-0) || 0 )
			if value > @ui.stars.length then value = @ui.stars.length
			if value < 0 then value = 0
			if value is 0
				@ui.stars.removeClass 'rating-active'
			else
				@ui.stars
				.eq -value
				.addClass 'rating-active'
				.siblings()
				.removeClass 'rating-active'

			@trigger "change", value, @

		onStarsClick: (e) =>
			return if @options.readOnly
			index = @ui.stars.index e.currentTarget
			return if index is -1
			index = 5-index
			@set index

			@trigger "click", index, @

		set: (val=0) =>
			val-=0
			if _.isNaN val then val = 0
			@model.set 'value', val

		get: =>
			@model.get 'value'