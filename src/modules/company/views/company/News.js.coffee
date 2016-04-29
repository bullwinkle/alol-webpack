@Iconto.module 'company.views', (Views) ->
	class Piece extends Marionette.ItemView
		className: 'piece'
		template: JST['company/templates/company/piece']

		ui:
			showMore: '.piece-show-more'
			showMoreText: '.piece-show-more span'
			message: '.piece-message'

		events:
			'click @ui.showMore': 'onShowMoreClick'

		onRender: =>
			imageUrl = @model.get('preview_image_url')
			@$('.piece-image').css 'background-image', "url(#{imageUrl})" if imageUrl

		onShowMoreClick: =>
			text = if @ui.showMoreText.text() is 'раскрыть' then 'свернуть' else 'раскрыть'
			@ui.showMore.toggleClass('rotate')
			@ui.showMoreText.text(text)
			@ui.message.toggleClass('line-clamp')

	class Views.CompanyNewsView extends Marionette.CompositeView
		className: 'company-news-view'
		template: JST['company/templates/company/news']
		childView: Piece
		childViewContainer: '.news-list'

		behaviors:
			Epoxy: {}

		bindings:
			".news-content": "toggle: not(state_isLoadingNews)"
			".loader-bubbles": "toggle: state_isLoadingNews"
			".no-news": "toggle: not(all(state_hasNews, not(state_isLoadingNews)))"

		initialize: ->
			@model = new Iconto.REST.Company id: @options.companyId
			@collection = new Iconto.REST.SocialContentCollection()

			@state = new Iconto.company.models.StateViewModel _.extend @options,
				hasNews: false
				isLoadingNews: true

		onRender: =>
			@collection.fetch(company_id: @model.get('id'), limit: 20, offset: 0, type: 'news', from: 'fb')
			.then (news) =>
				console.log news
				@state.set
					isLoadingNews: false
					hasNews: news.length > 0
			.dispatch(@)
			.catch (error) =>
				console.log error
				@state.set
					isLoadingNews: false
					hasNews: false