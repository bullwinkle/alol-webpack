localStorage = window.localStorage || {}

Iconto.module 'shared.services', (Services) ->

	class Services.Cart extends Backbone.Collection
		#private
		__singleton = null

		#public
		_options:
			companyId: 0
			storageKey: 'shoppingCartCollection'

		#singleton
		constructor: (properties={}, models, options={}) ->
			if __singleton
				if not properties.companyId or _.get(__singleton,'_options.companyId',null) is properties.companyId
					return __singleton

				_.extend __singleton._options, properties
				__singleton.reset __singleton.getFromStorage()
				return __singleton

			_.extend @_options, properties

			@model = Iconto.REST.ShopGood
			@url = this.model.prototype.urlRoot
			@comparator = options.comparator if options.comparator
			@_reset()
			@setToStorage = _.debounce @setToStorage,100
			@initialize.apply @, arguments

			modelsFromStorage = @getFromStorage()
			if modelsFromStorage
				@reset modelsFromStorage, _.extend {silent: true}, options

			__singleton = @
			@

		initialize: ->
			# posible events are:
			# http://backbonejs.org/#Events-catalog
			@on
				all: @onCollectionChange
				add: @logger.logProductAdd

		onCollectionChange: (type, model, args...) =>
			@setToStorage()

		getFromStorage: =>
			unless @_options.companyId
				return console.error "cart: can`t 'getFromStorage' : companyId required"

			modelsFromStorage = try
				JSON.parse(localStorage[@_options.storageKey])[ @_options.companyId ] || []
			catch err
				console.warn 'Cart.getFromStorage error:', err
				null
			modelsFromStorage

		setToStorage: =>
			unless @_options.companyId
				return console.error "cart: can`t 'setToStorage' : companyId required"

			modelsToSet = @toJSON()
			objToSet = try
				JSON.parse(localStorage[@_options.storageKey]) || {}
			catch err then {}

			objToSet[@_options.companyId] = modelsToSet
			localStorage[@_options.storageKey] = JSON.stringify objToSet
			objToSet

		logger:
			logProductAdd: _.debounce (product) =>
				alertify.success "Товар добавлен в корзину",2
			,50