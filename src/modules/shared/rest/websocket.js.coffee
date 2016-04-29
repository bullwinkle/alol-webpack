class Iconto.REST.WSModel extends Iconto.REST.AbstractModel

	url: =>
		result = @urlRoot

	#default method map - can be extended by 'methodMap' in child model class
	baseMethodMap =
		create: 'create'
		update: 'update'
		patch:  'patch'
		delete: 'delete'
		read:   'get'

	constructor: ->
		super
		@methodMap = _.extend {}, baseMethodMap, Marionette.getOption(@, 'methodMap')

	sync: (method, model, options) =>
		method = @methodMap[method] || method
		options ||= {}

		`
		if (options.data == null && (method === 'create' || method === 'update' || method === 'patch')) {
			options.data = options.attrs || this.toJSON();
		}
		`

		data = options.attr or options.data or {}

		resource = _.result @, 'url'
		data.id = @get(@idAttribute) unless @isNew()

		request = "REQUEST_#{resource.toUpperCase()}_#{method.toUpperCase()}"

		Iconto.ws.action(request, data)
#		.then (response) =>
#			@parse response, method

	parse: (data, method) =>
		data

	#TODO: remove this copy-paste from rest.js.coffee!
	fetch: (query, options) =>
		super
		.then (model) =>
				options ||= {}
				options.raw = true if _.isUndefined(options.raw)
				if @set(@parse(model, options), options)
					@trigger 'sync', @, model, options

				if options.raw is true
					model
				else
					@

	#TODO: remove this copy-paste from rest.js.coffee!
	save: (data, options) =>
		super
		.then (model) =>
				options ||= {}
				options.raw = true if _.isUndefined(options.raw)
				if @set(@parse(model, options), options)
					@trigger 'sync', @, model, options

				if options.raw is true
					model
				else
					@

class Iconto.REST.WSCollection extends Iconto.REST.AbstractCollection

	baseMethodMap =
		create: 'create'
		update: 'update'
		patch:  'patch'
		delete: 'delete'
		read:   'list'

	model: Iconto.REST.WSModel

	constructor: ->
		super
		@methodMap = _.extend {}, baseMethodMap, Marionette.getOption(@, 'methodMap')

	sync: (method, model, options) =>
		method = @methodMap[method]
		options ||= {}
		options.data ||= {}

		resource = _.result(@, 'url')

		request = "REQUEST_#{resource.toUpperCase()}_#{method.toUpperCase()}"

		options.parse = false #we use our own parse
		dfd = Iconto.ws.action(request, options.data)
		.then (response) =>
			@parse response, method
		model.trigger('request', model, dfd, options);
		dfd

	parse: (data, method) =>
		data

	fetch: (query, options) =>
		super
		.then (items) =>
				options ||= {}
				method = if options.reset then 'reset' else 'set'
				@[method](items, options)
				@trigger 'sync', @, items, options
				items

	fetchAll: (query, options) =>
		@fetch(query, options)