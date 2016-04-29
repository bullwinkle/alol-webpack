@Iconto.module 'shared.behaviors', (Behaviors) ->

	###
	params:
		storagePrefix: ''						- with this prefix model or collection will be stored in localstorage
		events:
			reset: ''							- with this event name this bindings will be removed
		bindings: [
			model: 'modelName'					- name of model, whitch will be synced with localstorage, model must be attached to view
			keys: ['keyName1', 'keyName2']		- keys of values, that will be synced with localstorage
		,
			collection: 'collectionName'		- name of collection, whitch will be synced with localstorage, collection must be attached to view
		]

	###

	class Behaviors.LocalStorageBinding extends Marionette.Behavior

		defaults:
			storagePrefix: "iconto_"
			bindings: []

		setToLocalStorage = (key='', data={}) ->
			window.localStorage.setItem key, JSON.stringify(data)

		getFromLocalStorage = (key='') ->
			JSON.parse window.localStorage.getItem key

		unsetFromLocalStorage = (key) ->
			window.localStorage.removeItem key

		initialize: (options, view) =>
			unless window.localStorage
				setToLocalStorage = -> true
				getFromLocalStorage = -> true
				unsetFromLocalStorage = -> true
			@storageNamePrefix = "#{@options.storagePrefix}#{@view.constructor.name}_"

			if @options.events?.reset
				@listenTo @view, @options.events?.reset, @resetStorageData

		onRender: =>
			binders = {}
			@options.bindings.forEach (binding) =>
				if binding.collection and @view[binding.collection]
					binders[ binding.collection ] = getFromLocalStorage "#{@storageNamePrefix}#{binding.collection}"
					@view[binding.collection].push binders[ binding.collection ]
					@bindCollectionToLocalStorage binding.collection, @view[binding.collection]
				else if binding.model and @view[binding.model]
					binding.keys ||= []
					binders[ binding.model ] = getFromLocalStorage "#{@storageNamePrefix}#{binding.model}"
					@view[binding.model].set binders[ binding.model ]
					@bindModelPropsToLocalStorage binding.model, @view[binding.model], binding.keys

		bindCollectionToLocalStorage: (collectionName, collection) =>
			@listenTo collection, 'all', =>
				@syncCollectionWithStorage collectionName, collection

		syncCollectionWithStorage: (collectionName, collection) =>
			_key = "#{@storageNamePrefix}#{collectionName}"
			if collection.length < 1
				unsetFromLocalStorage _key
			else
				setToLocalStorage _key, collection.toJSON()

		bindModelPropsToLocalStorage: (modelName, model, keys) =>
			keys.forEach (key) =>
				if model[key] then o[key] = model[key]
				event = "change:#{key}"
				@listenTo model, event, (model, value, options) =>
					@syncModelWithStorage modelName, model, keys

		syncModelWithStorage: (modelName, model, keys) =>
			newValue = {}
			keys.forEach (key) =>
				val = model.get key
				if !_.isUndefined val
					newValue[key] = val

			_key = "#{@storageNamePrefix}#{modelName}"
			if _.isEmpty newValue
				unsetFromLocalStorage _key
			else
				setToLocalStorage _key, newValue

		resetStorageData: =>
			@options.bindings.forEach (binding) =>
				if binding.collection and @view[binding.collection]
					unsetFromLocalStorage "#{@storageNamePrefix}#{binding.collection}"
				else if binding.model and @view[binding.model]
					unsetFromLocalStorage "#{@storageNamePrefix}#{binding.model}"