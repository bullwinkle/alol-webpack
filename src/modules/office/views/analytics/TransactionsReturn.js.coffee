@Iconto.module 'office.views.analytics', (Analytics) ->
	class Analytics.TransactionsReturnItemView extends Marionette.ItemView
		tagName: 'tr'
		template: JST['office/templates/analytics/transaction-return-item']
		className: 'transaction-return-item-view'

	class Analytics.TransactionsReturnEmptyView extends Marionette.ItemView
		tagName: 'tr'
		template: JST['office/templates/analytics/transaction-return-item-empty']
		className: 'transaction-return-item-empty-view'

	class Analytics.TransactionsReturnView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
		template: JST['office/templates/analytics/transactions-return']
		className: 'transactions-return-view mobile-layout'
		childView: Analytics.TransactionsReturnItemView
		emptyView: Analytics.TransactionsReturnEmptyView
		childViewContainer: '.list-wrapper .list'

		behaviors:
			Epoxy: {}
			InfiniteScroll:
				scrollable: '.fake'
			Form:
				events:
					submit: 'form'

		bindingSources: =>
			infiniteScrollState: @infiniteScrollState

		ui:
			childViewContainer: '.list-wrapper .list'
			date_from: '[name=date_from]'
			date_to: '[name=date_to]'
			loadMoreButton: '.load-more'
			sendButton: '.send'

		events:
			'click .reset-date-from': 'onResetDateFromClick'
			'click .reset-date-to': 'onResetDateToClick'
			'click @ui.loadMoreButton' : "onLoadMoreButtonClick"
#			'click @ui.sendButton': 'onSendButtonClick'

		modelEvents:
#			'change:date_from': -> console.log arguments
#			'change:date_to': -> console.log arguments
			'change:card_number': "onCardNumberChange"

		collectionEvents:
			'add remove change' : 'onCollectionChange'

		initialize: =>
			@model = new Iconto.REST.Transaction()

			@model.set
				date_from: moment().subtract(1, 'month').unix()
				date_to: moment().unix()

			@collection = new Iconto.REST.TransactionCollection()

			@state = new Iconto.office.models.StateViewModel @options
			@state.set
#				topbarTitle: 'Аналитика'
#				topbarSubtitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal, leadingComma: true)}"
				tabs: [
					title: 'Операции'
					href: "office/#{@options.company.id}/analytics/operations"
					active: @options.subpage is 'operations'
				,
					title: 'Возврат'
					href: "office/#{@options.company.id}/analytics/payment-return"
					active: @options.subpage is 'payment-return'
				]
				isLoading: false
				modelIsValid: true
				isEmpty: true
				isLoadingMore: false

				showResetDate: false

				dateFrom: ''
				dateTo: ''
				gotItems: false
				card_number: ""

			@listenTo @state,
				'change:card_number': @onStateCardNumberChange

			@infiniteScrollState.set 'limit',100

			@collection.comparator = (prev, next) =>
				if next.get('payment_time') > prev.get('payment_time')
					return 1
				else
					return -1

		onRender: =>
			Backbone.Validation.bind @ #TODO: find some time to figure out how to bind validation to multiple models

			unless Modernizr.inputtypes.date
				@state.set
					showResetDate: true

		getQuery: =>
			query =
				company_id: @options.companyId
				card_hash_sha1: @generateHashSha1 @model.get('card_number')
				card_hash_sha512: @generateHashSha512 @model.get('card_number')
				begin_date: @model.get 'date_from'
				end_date: @model.get 'date_to'
			query

		onResetDateFromClick: =>
			@model.set
				date_from: 0
			@$('input[name=date_from]').parent().find('input[data-is-datepicker]').val('').change()

		onResetDateToClick: =>
			@model.set
				date_to: 0
			@$('input[name=date_to]').parent().find('input[data-is-datepicker]').val('').change()

		onCollectionChange: =>
			if @collection.length > 0
				@state.set 'gotItems', true
			else
				@state.set 'gotItems', false

		onStateCardNumberChange: (state, value, options) =>
			console.log 'state', value
			parsedValue = value.replace(/\s/g, '')
			@model.set 'card_number', parsedValue, validate:true

		onCardNumberChange: (model, value, options) =>
			console.log 'model', value

		onFormSubmit: =>
			@reload()
			.finally =>
				@ui.childViewContainer.removeClass 'hide'

		onLoadMoreButtonClick: =>
			#complete: false
			#isEmpty: false
			#isLoadingMore: false
			#limit: 10
			#loadByIds: false
			#offset: 10
			return false if @infiniteScrollState.get('complete')
			newOffset = @infiniteScrollState.get('offset') + @infiniteScrollState.get('limit')
			@infiniteScrollState.set 'offset', newOffset
			@_loadMore()


		generateHashSha1: (source) =>
			return '' unless source
			CryptoJS.SHA1(source).toString()

		generateHashSha512: (source) =>
			return '' unless source
			CryptoJS.SHA512(source).toString()