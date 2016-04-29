class Iconto.REST.AbstractModel extends Backbone.Model

	url: =>
		# init with urlRoot, e.g. company
		url = @urlRoot

		# add id if exists, e.g. company/3116
		unless @isNew()
			url += "/#{@get(@idAttribute)}"

		# check api version, set default 2.0
		@version ||= '2.0'

		# if version isnt 2.0, add full path with leading https:
		# affects api.js -> $.ajaxPrefilter
		unless @version is '2.0'
			url = "#{window.ICONTO_API_URL.replace('2.0', @version)}#{url}"

		# return url
		url

	fetch: (query, options) =>
		options ||= {}
		options.data = query if query and not _.isEmpty query
		options.parse = true if _.isUndefined options.parse

		@sync('read', @, options)
		.catch (error) =>
			#console.error error
			@trigger 'error', @, error, options
			throw error #rethrow

	save: (data, options) =>
		options ||= {}

		if data and not _.isEmpty data
			options.attrs = @serialize data #if some values are specified in args - serialize them
		else
			options.attrs = @serialize @toJSON() #otherwise serilize the whole model
		options.validate = true if _.isUndefined options.validate
		options.parse = true if _.isUndefined options.parse

		method = if @isNew() then 'create' else 'update'

		@sync(method, @, options)
		.catch (error) =>
			#console.error error
			@trigger 'error', @, error, options
			throw error #rethrow

	serialize: (data) => #override this method to cast some of the values (e.g. cast strings to integers)
		data

	destroy: =>
		super
	#TODO: update model's deleted_at

	isNew: =>
		!@get(@idAttribute) #default implementation doesn't take into account that model's id cannot be 0

	getInvalidFields: =>
		obj = @toJSON()
		keys = _.keys obj
		res = {}
		_.each keys, (key, index) =>
			isValid = @isValid key
			if isValid then return
			res[key] = @get key
		res


class Iconto.REST.AbstractCollection extends Backbone.Collection
	model: Iconto.REST.AbstractModel

	initialize: =>
		@url = _.result @, 'url'
		@version ||= '2.0'

		# if version isnt 2.0, add full path with leading https:
		# affects api.js -> $.ajaxPrefilter
		unless @version is '2.0'
			@url = "#{window.ICONTO_API_URL.replace('2.0', @version)}#{@url}"

	fetch: (query, options) =>
		options ||= {}
		options.data = query || {}

		#update options with defaults
		options.remove = false if _.isUndefined options.remove #reset collection by default, to append loaded item pass remove:false to fetch
		options.merge = true if _.isUndefined options.merge #remove duplicates by default
		options.parse = true if _.isUndefined options.parse

		@sync('read', @, options)
		.catch (error) =>
			# cancellation error makes request loop, so avoid throw error if cancellation error
			unless error instanceof Promise.CancellationError
				@trigger 'error', @, error, options
				throw new ObjectError error

	#override default to return promise, not the model
	create: (model, options) =>
		`
			options = options ? _.clone(options) : {};
      if (!(model = this._prepareModel(model, options))) return false;
      if (!options.wait) this.add(model, options);
      var collection = this;
      var success = options.success;
      options.success = function(model, resp, options) {
        if (options.wait) collection.add(model, options);
        if (success) success(model, resp, options);
      };
      //return model;
		`
		return model.save(null, options);