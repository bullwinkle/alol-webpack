@Iconto.module 'order.views', (Views) ->

	class Views.ShopProductReviewEditView extends Marionette.ItemView
		template: JST['order/templates/shop/shop-review-edit']
		className: 'shop-product-reviews-view'

		behaviors:
			Epoxy: {}
			Form:
				submit: '[type=submit]'
				events:
					submit: 'form'

		ui:
			ratingWrapper: '.rating-wrapper'
			submitButton: '[type=submit]'
			deleteButton: '[delete]'
			allButtons: 'button'

		events:
			'click @ui.deleteButton': "onDeleteButtonClick"

		serializeData: =>
			product: @options.product
			user: Iconto.api.currentUser

		initialize: ->
			@model = @options.model or new Iconto.REST.ShopProductReview()

			if @model.isNew()
				@model.set
					persistent_id: @options.product.persistent_id
					user_id: Iconto.api.userId
					rating: @options.rating

			@model.set 'user',
				user_name: _.get Iconto, 'api.currentUser.nickname'
				user_photo: _.get Iconto, 'api.currentUser.image.url'

			@buffer = new @model.constructor @model.toJSON()

			# VIEW EVENT HANDLERS
		onRender: =>
			comRating = new Iconto.shared.components.Rating
				value: @model.get 'rating'
			comRating.render()
			@ui.ratingWrapper.append comRating.$el
			@listenTo comRating, 'change', @onRatingChange

		onShow: =>
			@state.set 'isLoading', false

		onRatingChange: (rating) =>
			@model.set 'rating', rating

		onDeleteButtonClick: =>
			@ui.allButtons.disableButton()
			@model.destroy()
			.then =>
				alertify.success "Ваш отзыв успешно удален"
				@model.trigger 'destroy:totally'
				Iconto.events.trigger('catalog:reviewForm:hide')
			.catch (err) =>
				console.warn err
				alertify.error "При удалении отзыва произошла ошибка, попробуйте позже"
			.done =>
				@ui.allButtons.enableButton()

		onFormSubmit: =>
			isNew = @model.isNew()
			changed = @buffer.set(@model.toJSON()).changed

			return false if !isNew and _.isEmpty changed

			@ui.allButtons.disableButton()
			@model.save()
			.then =>
				message = "Ваш отзыв успешно #{if isNew then 'сохранен' else 'обновлен'}"
				alertify.success message
				_.defer =>
					Iconto.events.trigger('catalog:reviewForm:hide')

			.catch (err) =>
				console.warn err
				alertify.error "При сохранении отзыва произошла ошибка, попробуйте позже"

			.done =>
				@ui.allButtons.enableButton()