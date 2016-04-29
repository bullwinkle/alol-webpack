Iconto.module 'shared.views', (Views) ->

	class CropperModel extends Backbone.Model
		defaults:
			src: ''
			dataUrl: ''
			ready: false

	class Views.Cropper extends Marionette.ItemView
		className: 'images-cropper-view'
		template: JST['shared/templates/cropper/cropper']

		ui:
			imageToCrop: '#image_to_crop'
			cropper: '#cropper'
			cropButton: '[name=crop]'
			rotateLeftButton: '.rotate-left'
			rotateRightButton: '.rotate-right'
			zoomInButton: '.zoom-in'
			zoomOutButton: '.zoom-out'

		events:
			'click @ui.cropButton' : 'onCropButtonClick'
			'click @ui.rotateLeftButton' : 'onRotateLeftButtonClick'
			'click @ui.rotateRightButton' : 'onRotateRightButtonClick'
			'click @ui.zoomInButton' : 'onZoomInButtonButtonClick'
			'click @ui.zoomOutButton' : 'onZoomOutButtonButtonClick'
			'zoom.cropper @ui.imageToCrop': 'onCropImageZoom'


		cropButtonBlocked = false
		initialize: ->
			@model = new CropperModel @options

			cropButtonBlocked = false

		onRender: =>
			@cropper = @ui.imageToCrop.cropper.bind @ui.imageToCrop

			cropperOptions =
				aspectRatio: 16 / 9,
				autoCropArea: 0.95,
				strict: true
				guides: false,
				highlight: false,
				dragCrop: false,
				cropBoxMovable: false,
				cropBoxResizable: false
				minContainerWidth: 280
				minContainerHeight: 280/(16/9)
				built: =>
					@model.set 'ready', true

			@ui.imageToCrop
			.attr 'src', @model.get('src')
			.one 'load', =>
				# TODO resize image to 1024px max to prevent crash on phones
				@cropper cropperOptions


		onCropImageZoom: (e) =>
			maxRatio = 30 # max zoom - 30x
			imageData = @ui.imageToCrop.cropper('getImageData')
			currentRatio = imageData.width / imageData.naturalWidth
			# Zoom in
			if e.ratio > 0 and currentRatio > maxRatio
				# Prevent zoom in
				e.preventDefault()
				# Fit the max zoom ratio
#				$(this).cropper 'setCanvasData', width: imageData.naturalWidth * maxRatio
				return false
			# Zoom in
			# ...
			return

		onRotateLeftButtonClick: =>
			return false unless @model.get 'ready'
			@cropper 'rotate', -45

		onRotateRightButtonClick: =>
			return false unless @model.get 'ready'
			@cropper 'rotate', 45

		onZoomInButtonButtonClick: =>
			return false unless @model.get 'ready'
			@cropper 'zoom', 0.5

		onZoomOutButtonButtonClick: =>
			return false unless @model.get 'ready'
			@cropper 'zoom', -0.5

		onCropButtonClick: =>
			return false if cropButtonBlocked or !@model.get 'ready'
			try
				canvas = @cropper('getCroppedCanvas')
			catch err
				console.error err
				window.alertify.error 'cropp error'
				return false

			cropButtonBlocked = true
			@ui.cropButton.addClass 'is-loading'
			@uploadCroppedImage @dataURItoBlob canvas.toDataURL()
			.then (data) =>
				throw 'Upload failed' unless data.url
				@trigger 'image:uploaded', data

			.catch (err) =>
				console.error err
				window.alertify.error 'cropp error'
			.done =>
				cropButtonBlocked = false
				@ui.cropButton.removeClass 'is-loading'

		dataURItoBlob: (dataURI) ->
			# convert base64/URLEncoded data component to raw binary data held in a string
			byteString = undefined
			if dataURI.split(',')[0].indexOf('base64') >= 0
				byteString = atob(dataURI.split(',')[1])
			else
				byteString = unescape(dataURI.split(',')[1])
			# separate out the mime component
			mimeString = dataURI.split(',')[0].split(':')[1].split(';')[0]
			# write the bytes of the string to a typed array
			ia = new Uint8Array(byteString.length)
			i = 0
			while i < byteString.length
				ia[i] = byteString.charCodeAt(i)
				i++
			new Blob([ ia ], type: mimeString)

		uploadCroppedImage: (blob) =>
			Iconto.shared.services.file.upload(blob)


