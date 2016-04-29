@Iconto.module 'shared.services', (Services) ->
	Services.file =

		getUploadUrl: (isCompanyUploadUrl) ->
			Iconto.api.get('file')
			.then (response) ->
				if isCompanyUploadUrl then response.data.company_logo_upload_url else response.data.file_upload_url

		upload: (file, options) ->
			options ||= {}
			Q.fcall =>
				options.url or @getUploadUrl()
			.then (url) ->
				data =
					url: url
					type: 'POST'
					data: file
					processData: false
					contentType: false

				if options.onProgress
					data.xhr = ->
						xhr = $.ajaxSettings.xhr()
						xhr?.upload?.addEventListener 'progress', (e) ->
							options.onProgress(e) if e.lengthComputable
						xhr

				Q($.ajax data)
				.then (response) ->
					if response.status is 0

						# fix for Grisha, some funny problem with php, when generated id was incremented
						imageId = _.get response, 'data.id'
						if imageId and !_.isNaN +imageId
							_.set response, 'data.id', +imageId

						return response.data
					else
						throw response

		crop: (options) =>
			Iconto.api.put('image', options)
			.then (response) =>
				if response.status is 0
					return response.data
				else
					throw response

		read: (file) =>
			reader = new FileReader()
			new Promise (resolve, reject) =>
				reader.onload = resolve
				reader.reject = reject
				return reader.reject() if not file
				reader.readAsDataURL(file)