@Iconto.module 'shared.views.qr', (QR) ->
	class QR.QRReaderView extends Marionette.ItemView
		className: 'qr-reader-view'
		template: JST['shared/templates/qr/qr-reader']

#		RATIO = 309 / 250 #taken from html5-qrcode
		RATIO = 4 / 3

		INTERVAL = 500

		ui:
			video: 'video'
			canvas: 'canvas'

		scan: =>
			if @localMediaStream
				@context.drawImage @video, 0, 0, 307, 250
				try
					qrcode.decode()
				catch e
					@trigger 'qr:fail', e

		onRender: =>
			if Iconto.shared.services.media.available
				_.defer =>
					width = @$el.width()
					height = Math.round(width / RATIO)

					canvas = @ui.canvas
					.attr(width: "#{width - 2} px", height: "#{height - 2} px")
#					.css(width: width - 2, height: height - 2)
					.get(0)
					@context = canvas.getContext('2d')
					@video = @ui.video
					.attr(width: "#{width} px", height: "#{height} px")
#					.css(width: width, height: height)
					.get(0)

					@localMediaStream = null

					window.URL = window.URL || window.webkitURL || window.mozURL || window.msURL;

					success = (stream) =>
						url = Modernizr.prefixed 'URL', window
						if window.URL and window.URL.createObjectURL
							@video.src = window.URL.createObjectURL(stream)
						else
							@video.src = stream
						@localMediaStream = stream
#						@video.play()
						@ui.video.addClass 'loaded'
						@trigger 'qr:success', stream
						@_interval = setInterval @scan, INTERVAL

					error = (error) =>
						@trigger 'qr:error', error

					qrcode.callback = (code) =>
						@trigger 'qr:read', code

					options = video: true
					Iconto.shared.services.media.getSources()
					.then (sources) =>
						source = _.find sources, (source) ->
							source.kind is 'video' and source.facing is 'environment'
						unless source
							source = _.find sources, (source) ->
								source.kind is 'video' and source.facing is 'user'
						if source
							options.video =
								optional: [
									{sourceId: source.id}
								]
						Iconto.shared.services.media.getUserMedia(options, success, error)

		resume: =>
			@_interval = setInterval @scan, INTERVAL

		pause: =>
			clearInterval @_interval

		onBeforeDestroy: =>
			delete @context
			delete @video
			@localMediaStream?.stop()
			delete @localMediaStream
			clearInterval @_interval