class Iconto.REST.File extends Iconto.REST.RESTModel
	url: 'file'

	getUploadUrl: (onlyUrl) =>
		d = $.Deferred()
		$.ajax(url:'file', type: 'OPTIONS')
		.done (response) =>
				d.resolve response.data.file_upload_url
		.fail (error) =>
				d.reject error
		d.promise()

	sendFile: (file) =>
		d = $.Deferred()
		@getUploadUrl()
		.done (url) =>
				console.log url
				xhr = new XMLHttpRequest()
				xhr.open 'POST', url, true
				xhr.onload = (response) =>
					console.log response
					response = $.parseJSON response.currentTarget.responseText
					if response.status is 0
						d.resolve response.data
					else
						d.reject response
				xhr.send file
		.fail (error) =>
				d.reject error
		d.promise()