@Iconto.module 'shared.views.autocomplete', (Autocomplete) ->

	class Autocomplete.BaseAutocompleteItemView extends Marionette.ItemView
		className: 'autocomplete-item-view'

		events:
			'click': 'onClick'

		initialize: (data) =>
			@$el.attr 'data-id', data.model.get('id')

		onClick: =>
			@trigger 'click', @model

	class AutocompleteStateViewModel extends Backbone.Model
		defaults:
			limit: 10
			offset: 0
			minLength: 3
			maxLength: 255
			query: ''

	class Autocomplete.BaseAutocompleteView extends Marionette.CompositeView
		#		className: do not use className here, it may be overridden in 'initialize'
		template: JST['shared/templates/autocomplete/autocomplete']
		childView: Autocomplete.BaseAutocompleteItemView
		childViewContainer: '.list'

		ui:
			input: 'input[data-autocomplete]'
			list: '.list'

		events:
			'input input[data-autocomplete]': 'onAutocompleteInput'
			'paste input[data-autocomplete]': 'onAutocompleteInput'
	#			'change input[data-autocomplete]': 'onAutocompleteInput'
			'keydown input[data-autocomplete]': 'onAutocompleteKeyDown'

		behaviors:
			InfiniteScroll:
				scrollable: '.autocomplete-list'
				offset: 200

		modelEvents:
			'change': 'onModelChange'

		getQuery: ->
			query: @state.get('query')

		initialize: =>
			@$el.addClass 'autocomplete-view'
			@options ||= {}

			@onAutocompleteInput = _.debounce @onAutocompleteInputFn, 300

			$('html').bind "click.#{@cid}", (e) =>
				@$el.removeClass('open')

			@model = new Backbone.Model()

			@state = new AutocompleteStateViewModel @options

			@$el.addClass('show-powered-by-google') if @options.poweredByGoogle

		update: (attrs) =>
			delete @state
			@state = new AutocompleteStateViewModel attrs

		childViewOptions: ->
			template: @state.get('childViewTemplate') or @childViewTemplate

		serializeData: ->
			state: @state.toJSON()

		clear: (preserveInput = false) =>
			#clear collection
			@collection.reset()
			#clear selected
			@model.set @model.defaults, silent: true
			@state.set
				offset: 0
				complete: false
				query: ''
			unless preserveInput
				@ui.input.val ''

		onAutocompleteInputFn: (e) =>
			value = $(e.currentTarget).val().trim()
			@trigger 'autocomplete:query', value

			# clear
			@clear true

			#set new query and clear offset and complete
			@state.set
				query: value

			@$el.removeClass 'empty'
			if value.length >= @state.get('minLength')
				#fetch new items
				@prevRequest?.catch(Promise.CancellationError).cancel()
				@loadMore()
				@$el.addClass('open')
			else
				@collection.reset();
				@$el.removeClass('open')

		onInfiniteScroll: =>
			#triggered in InfiniteScrollBehavior
			@loadMore()

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
			@prevRequest = @collection.fetchAll(params, {remove: false})
			.then (items) =>
				if @collection.length is 0
					@$el.addClass 'empty'

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


		onBeforeDestroy: =>
			$('html').unbind("click.#{@cid}")
			delete @prevRequest

		onAutocompleteKeyDown: (e) =>
			code = e.keyCode || e.which;
			$active = @ui.list.find('.autocomplete-item-view.active')
			$autocompleteItem = @ui.list.find('.autocomplete-item-view')
			switch code
				when 38
					$prev = $active.prev('.autocomplete-item-view')
					$active.removeClass('active')
					if $prev.get(0)
						e.stopPropagation()
						$prev.addClass('active')
						$prev.scrollIntoView()
				when 40
					e.stopPropagation();
					if $active.get(0)
						$next = $active.next('.autocomplete-item-view')
						if $next.get(0)
							$active.removeClass('active')
							$next.addClass('active')
							$next.scrollIntoView()
					else
						@ui.list.children().first().addClass('active')
				when 13
					$active = $autocompleteItem if $autocompleteItem.length is 1
					$active.addClass('active')
					if $active.get(0)
						id = $active.attr('data-id')
						`
							var active = this.collection.find(function(item) {
								return item.get('id') == id;
							});
							`
						#						active = @collection.find (item) =>
						#							item.get('id') is id


						if active
							@model.set @model.defaults, silent: true
							@model.set active.toJSON()
					@$el.removeClass('open')


		onChildviewClick: (childView, itemModel) =>
			@ui.list.find('.active').removeClass('active')
			childView.$el.addClass('active')
			@$el.removeClass('open')
			@model.set @model.defaults, silent: true
			@model.set itemModel.toJSON()

		onModelChange: =>
			if @model.get('id')
	#				@ui.input.val @model.get('company_name')
				@trigger 'autocomplete:selected', @model.toJSON()

		disable: =>
			@ui.input.prop 'disabled', true

		enable: =>
			@ui.input.prop 'disabled', false