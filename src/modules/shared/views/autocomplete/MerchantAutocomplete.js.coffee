#= require shared/views/autocomplete/BaseAutocomplete

@Iconto.module 'shared.views.autocomplete', (Autocomplete) ->
	class Autocomplete.MerchantAutocompleteView extends Autocomplete.BaseAutocompleteView
		className: 'merchant-autocomplete-view'
		collection: new Iconto.REST.AddressCollection()
		childViewTemplate: JST['shared/templates/autocomplete/merchant-autocomplete-item']

		initialize: =>
			super
			@model = new Iconto.REST.Address()

		loadMore: =>
			#if loaded all items
			return false if @state.get('complete')

			#lock loading
			return false if @lock
			@lock = true


			#set loading state
			@$el.addClass 'is-loading'

			state = @state.toJSON()
			params = _.extend @getQuery(), limit: state.limit, offset: state.offset
			@collection.fetchAll(params, {remove: false, silent: true, raw: false})
			.then (items) => #items - is array of !MODELS! because of raw:false
				if @collection.length is 0
					@$el.addClass 'empty'

			#update company_name
				companyIds = _.unique _.compact _.map items, (i) -> i.get('company_id')
				(new Iconto.REST.CompanyCollection()).fetchByIds(companyIds)
				.then (companies) =>
					@collection.each (address) =>
						if address.get('company_id')
							company = _.find companies, (c) ->
								c.id is address.get('company_id')
							if company
								address.set
									company_name: company.name
									icon_url: company.image.url
							else
								address.set
									company_name: ''
									icon_url: ''

					items
			.then (items) =>
				_.each items, (item) =>
					@collection.trigger 'add', item, @collection, remove: false

				@state.set
					offset: state.offset + items.length
				if items.length is 0 or items.length < state.limit
					#cannot load anymore
					@state.set 'complete', true
			.catch (error) =>
				console.error 'error', error
			.done =>
				@lock = false
				@$el.removeClass 'is-loading'