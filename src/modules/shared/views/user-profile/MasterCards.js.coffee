@Iconto.module 'shared.views.userProfile', (UserProfile) ->

	class MasterCardItemView extends Marionette.ItemView
		className: 'mastercard-item'
		template: JST['shared/templates/user-profile/mastercard-item']

		templateHelpers: ->
			getCardNumber: =>
				@model.get('card_number').replace(/(\d{4})/g, '$1 ')
			getCompanyImage: =>
				_.get(@company, 'image.url')
			getCompanyName: =>
				_.get(@company, 'name')

		initialize: ->
			@company = _.findWhere @options.companies, id: @model.get('company_id')
			@company = @options.company unless @company

	class MasterCardListView extends Marionette.CompositeView
		className: 'mastercard-list-wrapper'
		childView: MasterCardItemView
		template:  JST['shared/templates/user-profile/mastercard-list']
		childViewContainer: '.mastercard-list'

		childViewOptions: ->
			companies: @options.companies

	class UserProfile.MasterCardsView extends Marionette.LayoutView
		className: 'mastercards-view mobile-layout'
		template: JST['shared/templates/user-profile/mastercards']

		behaviors:
			Epoxy: {}
			Layout: {}

		regions:
			mastercardsRegion: '#mastercards'

		ui:
			topbarLeftButton: '.topbar-region .left-small'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'

		initialize: ->
			@model = new Iconto.REST.User(@options.user)

			@state = new Iconto.shared.models.BaseStateViewModel _.extend {}, @options,
				topbarTitle: 'МАСТЕР-КАРТЫ'
				topbarLeftButtonClass: ''
				topbarLeftButtonSpanClass: 'ic-chevron-left'
				isLoading: true

			@companies = new Iconto.REST.CompanyCollection()
			@masterCards = new Iconto.REST.MasterCardCollection()

		onRender: ->
			@masterCards.fetch()
			.then (cards) =>
				return unless @masterCards.length
				@companies.fetchByIds(_.compact(_.uniq(@masterCards.pluck('company_id'))))
			.then (companies) =>
				mastercardListView = new MasterCardListView
					collection: @masterCards
					companies: companies
				@mastercardsRegion.show mastercardListView
			.catch (error) =>
				console.error error
			.then =>
				@state.set
					isLoading: false

		onTopbarLeftButtonClick: =>
			defaultRoute = Backbone.history.fragment.split('/').slice(0, 2).join('/')
			parsedUrl = Iconto.shared.helpers.navigation.parseUri()
			fromRoute = _.get parsedUrl, 'query.from'
			route = fromRoute or defaultRoute
			Iconto.shared.router.navigate route, trigger: true