@Iconto.module 'operator.views', (Views) ->
	class Views.ChatItemView extends Iconto.chat.views.ChatItemView
		template: JST['operator/templates/chat-item']

		ui: _.extend @:: ui, operatorImage: '.operator-image'

		initialize: =>
			# extend room views with group info
			group = _.find @options.groups, (g) =>
				g.id is @model.get('group_id')
			@model.set group: group

			@listenTo @model, 'change:operator_id', @onOperatorIdChange

			super

		onRender: =>
			if @model.get('operator_id')
				(new Iconto.REST.User(id: @model.get('operator_id'))).fetch()
				.then (user) =>
					image = Iconto.shared.helpers.image.anonymous()
					if user.image.id
						image = Iconto.shared.helpers.image.resize(user.image.url, Iconto.shared.helpers.image.FORMAT_SQUARE_SMALL)
					@ui.operatorImage.attr src: image
					@showOperatorImage()
				.catch (err) ->
					console.error err
				.done =>

		onOperatorIdChange: (model, value) =>
			if value
				(new Iconto.REST.User(id: value)).fetch()
				.then (user) =>
					image = Iconto.shared.helpers.image.anonymous()
					if user.image.id
						image = Iconto.shared.helpers.image.resize(user.image.url, Iconto.shared.helpers.image.FORMAT_SQUARE_SMALL)
					@ui.operatorImage.attr src: image
					@showOperatorImage()
				.catch (error) ->
					console.error error
				.done()
			else
				@hideOperatorImage()

		showOperatorImage: =>
			@ui.operatorImage.css opacity: 1

		hideOperatorImage: =>
			@ui.operatorImage.css opacity: 0