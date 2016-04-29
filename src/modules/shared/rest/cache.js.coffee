cache = Iconto.REST.cache = {}

class Iconto.REST.AbstractCachableModel extends Iconto.REST.AbstractModel

	fetch: (query, options) =>
		key = @urlRoot
		cache[key] ||= {}
		id = @get('id')
		options ||= {}

		if options.reload or not cache[key][id]
			super.then (model) =>
				cache[key][id] = model
		else
			Q.fcall =>
				cache[key][id]

	save: (data, options) =>
		key = @urlRoot
		cache[key] ||= {}
		oldId = @get('id')
		delete cache[key]['current']
		cache[key][oldId] ||= {}
		super.then (model) =>
			if oldId #update existing model
				if model.id #got new id - don't forget to clear the cache
					#1 - old cache, 2 - passed data attributes, 3 - server response
					cache[key][model.id] = _.extend {}, cache[key][oldId], data or {}, model or {}
					delete cache[key][oldId] # clear old cache
				else
					#update previous cache
					_.extend cache[key][oldId], data or @toJSON(), model or {}
			else
				#create new model
				cache[key][model.id] = _.extend @toJSON(), data or {}, model or {}

			model

	destroy: =>
		key = @urlRoot
		id = @get('id')
		cache[key] ||= {}
		super.then =>
			delete cache[key][id]
#TODO: update model's deleted_at

	invalidate: =>
		key = @urlRoot
		id = @get('id')
		delete cache[key][id]

#ABSTRACT
class Iconto.REST.AbstractCachableCollection extends Iconto.REST.AbstractCollection

	model: Iconto.REST.AbstractCachableModel

	fetch: (query, options) =>
		query ||= {}
		key = _.result(@, 'url')
		cache[key] ||= {}
		delete cache[key]['current']
		keyCache = cache[key] ||= {}
		options ||= {}
		if query.ids
			#request with ids

			#iterate over requested ids to find out what entities to load and what to take from cache
			idsToLoad = []
			result = {}
			unless options.reload
				`
					for (var i=0, _len = query.ids.length; i<_len; i++) {
						var id = query.ids[i],
								cached = keyCache[id];
						if (cached) {
							result[id] = cached;
						} else {
							result[id] = null;
							idsToLoad.push(id);
						}
					}
					//now ids to load are stored in idsToLoad in load order
					//moreover positions in result to insert loaded entities are reserved by 'nulls' - result[id]=null
					`
			else
				idsToLoad = query.ids

			if idsToLoad.length > 0
				#there are entities to load
				query.ids = idsToLoad

				return super(query, options).then (items) =>
					for entity in items
						#update cache and result
						result[entity.id] = keyCache[entity.id] = entity
					#return merged result
					_.compact _.toArray(result)

			else
				#nothing to load
				return Q.fcall ->
					_.toArray(result)


		else if !_.isUndefined(query.limit) and !_.isUndefined(query.offset)
			#request with limit and offset
			return super(query, options).then (items) =>
				items ||= []
				#just update cache
				keyCache[entity.id] = entity for entity in items
				items

		else if options.cache
			defaultCasheLiveTime = options.cacheTime || 60*60*1000 # 1 hour
			cached = keyCache[JSON.stringify(query)]
			if cached and (+(new Date()) - cached.time) < defaultCasheLiveTime
				@_lastResponseMeta = cached.meta if cached.meta
				return Q.fcall -> _.toArray(cached.items)
			return super(query, options).then (items=[]) =>
				keyCache[JSON.stringify(query)] = {
					items: items
					meta: @_lastResponseMeta
					time: +(new Date())
				}
				items
		else
			#other request
			return super