#= require shared/views/modals/Prompt

@Iconto.module 'shared.views.modals', (Modals) ->
	
	class Modals.ImageCropModalView extends Iconto.shared.views.modals.Prompt
		className: 'tiny reveal-modal'
		template: JST['templates/modals/image-crop']

		events:
			'click .destroy': 'onDestroyClick'
			'click #save-image-crop-button': 'onSaveImageCropClick'
			'click .destroy-reveal-modal': 'onDestroyRevealModalClick'

		ui:
			smallImage: '.small-image'

		initialize: (options) =>
			@original_url = options.url || throw new Error 'Image url must be exist'

		onRender: =>
			$(document).on 'open', '[data-reveal]', =>
				$(document).off 'open', '[data-reveal]'
				@ui.smallImage.load =>
					_sI = @ui.smallImage.get(0)
					@makeCrop
						nW: _sI.naturalWidth
						nH: _sI.naturalHeight
						w: @ui.smallImage.width()
						h: @ui.smallImage.height()
				@ui.smallImage.attr 'src', @original_url

		makeCrop: (sizes) =>
			{nW, w, nH, h} = sizes
			that = @
			@ratioW = nW / (w || 200)
			@ratioH = nH / (h || 200)
			minX = 200 / @ratioW
			minY = 200 / @ratioH
			@ui.smallImage.Jcrop
				minSize: [minX, minY]
				aspectRatio: 1
				setSelect: [0, 0, minX, minY], () ->
					that.jcrop = @

		onDestroyRevealModalClick: =>
			@hide()

		onSaveImageCropClick: =>
			r = @jcrop.tellSelect()
			@trigger 'image:cropped',
				width: Math.round r.w * @ratioW
				height: Math.round r.h * @ratioH
				x1: Math.round r.x * @ratioW
				y1: Math.round r.y * @ratioH

		destroy: =>
			@onDestroyRevealModalClick()