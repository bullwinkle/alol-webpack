#= require ./BaseModal

@Iconto.module 'shared.views.modals', (Modals) ->

	inherit = Iconto.shared.helpers.inherit

	class LightBoxModel extends Modals.BaseModel
		defaults:{}

	destroy = Marionette.LayoutView.prototype.destroy

	class Modals.LightBox extends Marionette.LayoutView

		#private
		touchStartedOnContent = false

		className: 'lbx-overlay'
		visibleClassName: 'visible'

		template: JST['shared/templates/modals/lightbox']

		regions:
			content: '.lbx-content'

		ui:
			wrapper: '.lbx-wrapper'
			content: '.lbx-content'
			closeButton: '.close-button'
			contentRegion: '.lbx-content'

		events: ->
			events = # common events
				'mousewheel' : 'onMousewheel'

			if @options.img then _.extend events,
				'click @ui.wrapper, @ui.closeButton, .cropper-drag-box' : 'onSomeWhereClick'
				'click .cropper-face': 'onContentClick'
			else _.extend events,
				'click' : 'onSomeWhereClick'
				'click @ui.closeButton' : 'onSomeWhereClick'
				'mousedown @ui.content': 'onContentTouchStart'
				'touchstart @ui.content': 'onContentTouchStart'
				'dragstart @ui.content': 'onContentTouchStart'
				'mouseup': 'onContentTouchEnd'
				'touchend': 'onContentTouchEnd'
				'dragend': 'onContentTouchEnd'
				'click @ui.content': 'onContentClick'
			events

		initialize: (options) ->
			@model = new LightBoxModel options

		onAttach: =>
			if @options.view and @options.options
				@showView()
			else if @options.html
				@showHtml()
			else if @options.img
				@showImg()

		onShow: =>
			@ui.body = $('body')
			@listenTo @ui.body,
				'keydown': @onKeyTouch
				'keypress': @onKeyTouch
				'keyup': @onKeyTouch

			defer = =>
				@$el.addClass 'visible'
			setTimeout defer, 10

		onSomeWhereClick: (e) =>
			e.stopPropagation()
			# do not close when you start click on content block and ends on outside
#			return false if ( touchStartedOnContent and !@options.img)
			return false if ( touchStartedOnContent)
			@destroy()

		onContentClick: (e) =>
#			if @options.img
#				return true
			e.stopPropagation()

		onContentTouchStart: (e) =>
			touchStartedOnContent = true

		onContentTouchEnd: (e) =>
			_.defer =>
				touchStartedOnContent = false

		onCloseButtonClick: (e) =>
			@destroy()

		onKeyTouch: (e) =>
			switch e.type
				when 'keydown'
					switch e.keyCode
						when 27 then @destroy()
			true

		showView: =>
			View = @model.get 'view'
			viewOptions = @model.get 'options'
			view = new View viewOptions
			@proxyEvents view
			@content.show view

		showHtml: =>
			html = $(@model.get('html'))
			@ui.contentRegion.append html

		showImg: =>
			$img = $("<img class=\"lbx-image\" src=\"#{ @model.get('img') }\"/>")
			@$el.addClass 'image image-is-loading'
			@ui.contentRegion.append $img

			# cropper
			@cropper = $img.cropper.bind $img

			cropperOptions =
				autoCropArea: 1
				viewMode:4
				modal: false
				strict: true
				highlight: false
				background: false
				center: false
				cropBoxMovable: false
				cropBoxResizable: false
				guides: false
				dragCrop: false
				checkCrossOrigin:true
			_.extend cropperOptions,
			if @options.noResize
				zoomable:false
				zoomOnTouch:false
				zoomOnWheel:false
				movable:false
				scalable:false
			else
				zoomable:true
				zoomOnTouch:true
				zoomOnWheel:true
				movable:true
				scalable:true

				built: =>
					_.defer =>
						@$el.removeClass 'image-is-loading'

			$img
			.one 'load', =>
				@cropper cropperOptions


		proxyEvents: (view) =>
			@listenTo view, 'all', (event, args...) =>
				@trigger event, args

		onBeforeDestroy: =>
			@stopListening @ui.body, 'keydown', @onKeyTouch
			@stopListening @ui.body, 'keypress', @onKeyTouch
			@stopListening @ui.body, 'keyup', @onKeyTouch

		destroy: =>
			if @$el.hasClass @visibleClassName
				# console.log 'destroy'
				@$el.removeClass @visibleClassName
				@$el.one Iconto.shared.helpers.transitionEndEventName, destroy.bind(@)
			else
				super()

		onMousewheel: (e) =>
			undefined

		@hide: =>
			App.lightbox.empty()

		@show: (options) =>
			lightbox = new Modals.LightBox options
			App.lightbox.show lightbox
			lightbox