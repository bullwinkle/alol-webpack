@Iconto.module 'order.views', (Views) ->

	class Views.ShopProductReviewsItemView extends Marionette.ItemView
		template: JST['order/templates/shop/shop-product-reviews-item']
		tagName: 'li'
		className: 'shop-product-reviews-item-view flexbox t-grey l-pt-15'

		ui:
			ratingWrapper: '.rating-wrapper'
			editButton: '[edit-button]'

		events:
			'click @ui.editButton': 'onEditButtonClick'

		onRender: =>
			comRating = new Iconto.shared.components.Rating
				readOnly:true
				value: @model.get 'rating'
			comRating.render()
			@ui.ratingWrapper.append comRating.$el

		onEditButtonClick: =>
			@trigger 'click:edit', @model

	class Views.ShopProductReviewsView extends Iconto.shared.views.infinite.BaseInfiniteCompositeView
		template: JST['order/templates/shop/shop-product-reviews']
		className: 'shop-product-reviews-view'
		childViewContainer: '#reviews-list'
		childView: Views.ShopProductReviewsItemView
		childEmptyView: Views.ShopProductReviewsItemView

		behaviors:
			Epoxy: {}
			Layout:
				template: false
			InfiniteScroll:
				scrollable: undefined # it passed to view.options from parent layout
				offset: 8000

		ui:
			ratingWrapper: '.rating-wrapper'
			currentUserReviewWrapper: '#current-user-review'
			orderByUpdatedAt: "[order-by=updated_at]"
			orderByRating: "[order-by=rating]"

		events:
			'click @ui.orderByUpdatedAt' : "onToggleOrderClick"
			'click @ui.orderByRating' : "onToggleOrderClick"

		bindingSources: ->
			infiniteScrollState: @infiniteScrollState

		initialize: ->
#			@onSortOrderTogglerClick = _.debounce @onSortOrderTogglerClick, 100


			@state = new Iconto.shared.models.StateListViewModel _.extend {}, @options,
				hasCurrentUserReview: false
				sortBy: 'updated_at' # rating | updated_at
				orderBy:
					updated_at: 'desc' # asc | desc
					rating: 'desc'

			@collection = new Iconto.REST.ShopProductReviewCollection()

			@infiniteScrollState.set
				limit: 20

			@listenTo @state,
				'change:sortBy': @reload
				'change:orderBy': @reload

			@currentUserReview = new Iconto.REST.ShopProductReview()
			@currentUserReviewView = new @childView
				model: @currentUserReview

			@listenTo @currentUserReview,
				'change:id': (model, id) =>
					@state.set 'hasCurrentUserReview', !!id
					unless model.previous('id')
						@showCurrentUserReview()

				'sync': =>
					@showCurrentUserReview()
					@trigger 'reviews:updated'

				'destroy': =>
					@state.set 'hasCurrentUserReview', false
					@currentUserReviewView.$el.addClass 'hide'
					@currentUserReview.set @currentUserReview.defaults

				# custom event, emited after DELETE request (destroy event emits before request)
				'destroy:totally': =>
					@trigger 'reviews:updated'

			@listenTo @currentUserReviewView,
				'click:edit': @onCurrentUserReviewClickEdit

		# VIEW EVENT HANDLERS
		onRender: =>
			@ui.orderByUpdatedAt.trigger 'click'

			comRating = new Iconto.shared.components.Rating
				mod: 'm-mobile-big'
			.render()

			@ui.ratingWrapper.append comRating.$el
			@listenTo comRating, 'click',@onRatingClick

			@reload()

			(new @currentUserReview.constructor).fetch
				filters:
					persistent_id: @options.persistentId
					user_id: Iconto.api.userId
			,
				reload: true
			.then (res) =>
				res = _.get res, 'items[0]', {}
				return undefined unless res.user_id is Iconto.api.userId
				res.user =
					user_name: _.get Iconto, 'api.currentUser.nickname'
					user_photo: _.get Iconto, 'api.currentUser.image.url'
				@currentUserReview.set res
				@showCurrentUserReview()

			.catch (err) =>
				console.warn '@currentUserReview.fetch', err

		onToggleOrderClick: (e) =>
			if @onToggleOrderClick.prevClick is e.currentTarget
				orderBy = @state.get('orderBy')
				sortBy = orderBy[@state.get('sortBy')]
				@state.get('orderBy')[@state.get('sortBy')]
				switchOrder = switch  orderBy[@state.get('sortBy')]
					when "asc" then "desc"
					when "desc" then "asc"
				orderBy[@state.get('sortBy')] = switchOrder

				@state.set 'orderBy': orderBy
				@state.trigger 'change:orderBy'
			@onToggleOrderClick.prevClick = e.currentTarget

		onRatingClick: (rating, comRating) =>
			@showReviewEditForm rating, @currentUserReview
			_.defer => comRating.set 0

		onCurrentUserReviewClickEdit: (currentReview) =>
			@showReviewEditForm null, currentReview

		showCurrentUserReview: =>
			@currentUserReview.set 'currentUserReview',true
			@currentUserReviewView.render()
			@currentUserReviewView.$el.removeClass 'hide'
			@ui.currentUserReviewWrapper.append @currentUserReviewView.$el

		showReviewEditForm: (rating, currentReview) =>
			parentLayout = _.result @, '_parentLayoutView'
			product =  _.result parentLayout, 'model.toJSON'
			Iconto.events.trigger 'catalog:reviewForm:show',
				{ rating, product, currentReview }

		onShow: =>
			@state.set 'isLoading', false

		getQuery: =>
			orders = {}
			sortBy = @state.get('sortBy')
			orderBy = @state.get('orderBy')
			sortBy[orderBy]
			orders[sortBy] = @state.get('orderBy')[@state.get('sortBy')]

			return {
				orders
				filters:
					persistent_id: @options.persistentId
				conditions:
					user_id:
						"<>": Iconto.api.userId
			}