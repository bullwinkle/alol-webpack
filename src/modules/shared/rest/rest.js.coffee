methodMap =
	create: 'post'
	update: 'put'
	patch:  'patch'
	delete: 'delete'
	read:   'get'
	ids:    'get'
	count:  'get'

class Iconto.REST.RESTModel extends Iconto.REST.AbstractCachableModel

	sync: (method, model, options) ->
		method = methodMap[method] or method
		data = options.attrs or options.data
		url = _.result(model, 'url')
		unless url
			throw new Error('A "url" property or function must be specified')

		if method is 'get' and data and data['ids']
			url += '?_method=get'
			method = 'post'

		promise = Iconto.api[method](url, data)
		.then (response) ->
			response.data
		model.trigger 'request', model, promise, options
		promise

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

class Iconto.REST.RESTCollection extends Iconto.REST.AbstractCachableCollection
	model: Iconto.REST.RESTModel

	sync: (method, model, options) =>
		promise = Iconto.REST.RESTModel::sync.apply @, arguments
		handler = (response) =>
			@_lastResponseMeta = _.pick response, [ 'pagination' ]

			switch method #response already is 'data' - from Iconto.REST.RESTModel.prototype.sync
				when 'count'
					response.count or 0
				else #including 'ids'
					response.items or []

		promise.then handler.bind(@)

	fetch: (query, options) =>
		super
		.then (items) =>
			options ||= {}
			options.raw = true if _.isUndefined(options.raw)
			method = if options.reset then 'reset' else 'set'
			result = @[method](items, options)
			@trigger 'sync', @, items, options
			if options.raw is true
				items
			else
				result

	fetchByIds: (ids, options) =>
		@fetch(ids: ids, options)

	fetchIds: (query) =>
		@sync('ids', @, data: query)

	fetchAll: (query, options) =>
		query ||= {}
		if query.ids
			@fetchByIds(query.ids, options)
		else if !_.isUndefined(query.limit) and !_.isUndefined(query.offset)
			@fetch(query, options)
		else
			@fetchIds(query, options)
			.then (ids) =>
					@fetchByIds(ids, options)

	count: (query) =>
		@sync('count', @, data: _.extend(_method: 'count', query))