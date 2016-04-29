@Iconto.module 'shared.views', (Views) ->

############################################ MODELS #############################################
	class SlideModel extends Backbone.Model
		defaults:
			imageUrl: ''
			direction: 'rtl'
			visible: false
			animate: false

	class SlideCollection extends Backbone.Collection
		model: SlideModel

	class SliderModel extends Backbone.Model
		defaults:
			isEmpty: true
			animate: false
			multipleImages: false
			currentSlideIndex: 0
			previousSlideIndex: null
			options:
				isInfinite: true

############################################# VIEWS #############################################
	class Slide extends Marionette.ItemView
		template: JST['shared/templates/slider/image-slide']
		className: 'slide hidden'

		initialize: ->
			@listenTo @model, 'change:visible', @update

		update:(model, visible, options) =>
			direction = model.get 'direction'
			animate = model.get 'animate'
			# fix this !!!!!!!!!!!!!!!
#			console.log animate
			if animate
				if visible
					switch direction
						when 'rtl'
							@slideFromRight()
						when 'ltr'
							@slideFromLeft()
				else
					switch direction
						when 'rtl'
							@slideToLeft()
						when 'ltr'
							@slideToRight()
			else
				if visible
					@showSlide()
				else
					@hideSlide()
			@trigger 'update'

		showSlide: =>
			@$el.removeClass 'hidden'

		hideSlide: =>
			@$el.addClass 'hidden'

		slideFromRight: => @el.className = 'slide slide-from-right'
		slideFromLeft: => @el.className = 'slide slide-from-left'
		slideToRight: => @el.className = 'slide slide-to-right'
		slideToLeft: => @el.className = 'slide slide-to-left'

	class Views.ContentSlider extends Marionette.CompositeView
		template: JST['shared/templates/slider/images-slider']
		className: 'content-slider-container'
		childViewContainer: '.slider'
		childView: Slide

		ui:
			# blocks
			sliderContainer : '.slider-container'
			slider : '.slider'
			slides : '.slider .slide'
			images : '.slider .slide .image'
			sliderControls : '.slider-controls'

			# controls
			prev : '.prev'
			next : '.next'
			paginationItems : '.pagination-item'

		events:
			'click @ui.prev': 'onSlidePrevClick'
			'click @ui.next': 'onSlideNextClick'
			'click @ui.paginationItems': 'onPaginationItemClick'

		initialize: ->
			@options.images ||= []
			imagesLength = @options.images.length
			if imagesLength > 0
				@options.isEmpty = false
				if imagesLength is 1
					@options.multipleImages = false
				else
					@options.multipleImages = true
			else
				@options.isEmpty = true
				@options.multipleImages = false
				@el.className = 'slider-container empty'

			@model = new SliderModel @options

			images =  for imageUrl in @options.images
				imageUrl: imageUrl
				visible: false

			@collection = new SlideCollection images

			transform = Modernizr.prefixed('transform')

			@once 'childview:update', @onceItemviewItemUpdated

		onRender: =>
			currentSlideIndex = @model.get 'currentSlideIndex'
			currentSliderModel = @collection.models[ currentSlideIndex ]
			if currentSliderModel then currentSliderModel.set 'visible', true

			@ui.paginationItems.eq( currentSlideIndex ).addClass('active')

			@listenTo @model, 'change:currentSlideIndex', @slideToIndex

		onChildviewRender: (slide) =>
			slide.model.listenTo @model, 'change:animate', =>
				slide.model.set 'animate', @model.get('animate')

		onceItemviewItemUpdated: =>
			if @collection.length > 1
				@model.set 'animate', true

		onContainerClick: =>
			if @collection.length is 1
				@trigger 'click'

		onSlidePrevClick: =>
			currentSlideIndex = @model.get 'currentSlideIndex'

			if @model.get('options').isInfinite
				if currentSlideIndex is 0
					newSlideIndex = @collection.length-1
				else
					newSlideIndex = currentSlideIndex-1
			else
				return false if currentSlideIndex is 0
				newSlideIndex = currentSlideIndex-1

			@model.set
				currentSlideIndex: newSlideIndex
				previousSlideIndex: currentSlideIndex
				direction: 'ltr'

		onSlideNextClick: =>
			currentSlideIndex = @model.get 'currentSlideIndex'

			if @model.get('options').isInfinite
				if currentSlideIndex is @collection.length-1
					newSlideIndex = 0
				else
					newSlideIndex = currentSlideIndex+1
			else
				return false if currentSlideIndex is @collection.length-1
				newSlideIndex = currentSlideIndex+1

			@model.set
				currentSlideIndex: newSlideIndex
				previousSlideIndex: currentSlideIndex
				direction: 'rtl'

		onPaginationItemClick: (e) =>
			currentSlideIndex = @model.get 'currentSlideIndex'

			newSlideIndex = $(e.target).data('index')
			@model.set
				currentSlideIndex: newSlideIndex
				previousSlideIndex: currentSlideIndex
				direction: 'auto'

		slideToIndex: =>
			previousSlideIndex = @model.get 'previousSlideIndex'
			currentSlideIndex = @model.get 'currentSlideIndex'
			direction = @model.get 'direction'

			if direction is 'auto'
				if currentSlideIndex > previousSlideIndex
					direction = 'rtl'
				else
					direction = 'ltr'

			previousSliderModel = @collection.models[ previousSlideIndex ]
			previousSliderModel.set
				visible: false
				direction: direction

			currentSliderModel = @collection.models[ currentSlideIndex ]
			currentSliderModel.set
				visible: true
				direction: direction

			@ui.paginationItems.removeClass('active')
			@ui.paginationItems.eq( currentSlideIndex ).addClass('active')

