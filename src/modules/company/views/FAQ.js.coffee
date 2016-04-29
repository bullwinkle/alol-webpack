@Iconto.module 'company.views', (Views) ->

	# FAQ tree-view recourcive item rendering
	class Views.FAQItemCompositeView extends Marionette.CompositeView
		tagName: 'li'
		className: 'faq-item button list-item menu-item'
		template: JST['company/templates/FAQ/faq-item']
		childView: Views.FAQItemCompositeView
		childViewContainer: '.list'
		behaviors:
			Epoxy: {}

		ui:
			childList: '.list-wrapper'
			closeButton: '.close'

		events:
			'click': 'onClick'
			'click @ui.closeButton': 'onCloseButtonClick'

		modelEvents:
			'change:isOpened': 'toggleIsOpened'

		collectionEvents:
			'add remove': 'onCollectionChange'

		initialize: ->
			@onCollectionChange = _.debounce @onCollectionChange, 200

			unless _.get(@model.get('children'), 'length') then @model.set('children', [])
			children = @model.get('children')
			@collection = new Iconto.REST.CompanyFAQCollection()
			if children.length > 0
				@collection.add children

		onRender: =>
			switch @model.get 'type'
				when Iconto.REST.CompanyFAQ.TYPE_CATEGORY
					@$el.addClass 'category'
					if @collection.length > 0
						@$el.addClass 'with-items'
				when Iconto.REST.CompanyFAQ.TYPE_QUESTION
					@$el.addClass 'category-item'
				else
					@$el.addClass 'hide'

		onCollectionChange: =>
			@state.set 'gotChildren': !!@collection.length
			methodName = "#{if @collection.length then 'add' else 'remove'}Class"
			@$el[methodName] 'with-items'

		# pass 'question:send' event to parent view
		onChildviewQuestionSend: (view, question) =>
			@trigger 'question:send', question

		onChildviewChangeOpen: (view, model) =>
			@trigger 'change:open', view.model
			if @collection.length
				hasOpened = !!@collection.find (el) -> !!el.get('isOpened')
				@$el["#{if hasOpened then 'add' else 'remove'}Class"] 'has-opened'
				@toggleRerender()

		onClick: (e) =>
			e.stopPropagation()
			switch @model.get 'type'
				when Iconto.REST.CompanyFAQ.TYPE_CATEGORY
					return unless @collection.length > 0
					@model.set 'isOpened', true
				when Iconto.REST.CompanyFAQ.TYPE_QUESTION
					@sendQuestion()

		onCloseButtonClick: (e) =>
			e.stopPropagation()
			@model.set 'isOpened', false

		toggleIsOpened: (model, isOpened, options) =>
			@trigger 'change:open', @model
			if isOpened
				parentsScrollTop = @$el.parents('.scroll-parent').eq(0).scrollTop()
				@ui.childList.css 'top', parentsScrollTop
			else
				defer = =>
					@ui.childList.css 'top', ''
				setTimeout defer,220
			@$el["#{if isOpened then 'add' else 'remove'}Class"] 'is-opened'

		toggleRerender: =>
			@$el.addClass('rerender-trigger')
			_.defer =>
				@$el.removeClass('rerender-trigger')

		sendQuestion: =>
			@trigger 'question:send', @model.toJSON()


	# FAQ tree-view empty view
	class Views.FAQEmptyView extends Marionette.ItemView
		tagName: 'li'
		className: 'faq-item text-center f-lh-50'
		template: -> 'Для этой компании нет FAQ'


	# FAQ tree-view root list
	class Views.FAQTreeView extends Marionette.CompositeView
		className: 'faq-list-view scroll-parent'
		childView: Views.FAQItemCompositeView
		emptyView: Views.FAQEmptyView
		template: JST['company/templates/FAQ/faq-list']
		childViewContainer: '.list'
		behaviors:
			Epoxy: {}
		ui:
			innerLists: '.inner-lists-wrapper'
		events: {}
		collectionEvents:
			'add remove': 'onCollectionChange'

		onCollectionChange: =>
			@state.set 'gotChildren': !!@collection.length
			methodName = "#{if @collection.length then 'add' else 'remove'}Class"
			@$el[methodName] 'with-items'

		initialize: ->
			@collection = new Iconto.REST.CompanyFAQCollection()

			@state = new Iconto.shared.models.BaseStateViewModel _.extend {}, @options,
				isVisible: false

			@state.set 'isLoadingMore', true

			@listenTo @state, 'change:isVisible', @onIsVisibleChange
			@on 'toggle:visible', (isVisible, parentState) =>
				@state.set 'isVisible', isVisible

			companyId = @options.companyId
			@collection.fetch @getQuery(), {parse: true}
			.catch (err) =>
				console.error err
			.done () =>
				@state.set isLoadingMore: false
				@trigger 'faq:ready', @collection.length

		getQuery: =>
			companyId = @options.companyId
			filters: company_id: companyId

		onIsVisibleChange: (state, isVisible) =>
			@calculateHeight isVisible
			.then (height) =>
				@$el.css height:height
			.catch (err) =>
				@$el.css height:''

		onChildviewQuestionSend: (view, question) =>
			@trigger 'faq:question:send', question

		onChildviewChangeOpen: =>
			hasOpened = !!@collection.find (el) -> !!el.get('isOpened')
			@$el["#{if hasOpened then 'add' else 'remove'}Class"] 'has-opened'
			@toggleRerender()

		toggleRerender: =>
			@$el.addClass('rerender-trigger')
			_.defer =>
				@$el.removeClass('rerender-trigger')

		calculateHeight: (isVisible) =>
			return new Promise (resolve, reject) =>
				$vc = @$el.parents('.view-content')
				$messages = $vc.find '.messages'
				$submitForm = $vc.find '.actions'
				defer = =>
					height = $vc.outerHeight(true) - parseFloat($messages.css('min-height')) - $submitForm.outerHeight(true)
					resolve height
				if isVisible
					setTimeout defer, 0
				else
					# need empty string here to totally remove inline height from inline styles
					resolve ''
