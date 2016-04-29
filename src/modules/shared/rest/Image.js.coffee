class Iconto.REST.Image extends Iconto.REST.RESTModel
	urlRoot: 'image'

	cropImage: (data) =>
		d = $.Deferred()
		$.ajax(url: 'image', type: 'PUT', data: data)
		.done (response) =>
				d.resolve response
		.fail (error)=>
				d.reject error
		d.promise()