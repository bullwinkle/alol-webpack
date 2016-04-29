@Iconto.module 'shared.views.updatableregion', (UpdatableRegion) ->

	class UpdatableRegion.UpdatableRegion extends Marionette.Region
		initialize: ->
			@initAnimationBehavior() if @options.animate

		showOrUpdate: (viewClass, viewOptions, _updateOptions) =>
			updateOptions = _.defaultsDeep _.get(viewOptions, 'updateOptions', {}),
				clearState: true
			_.extend viewOptions, _updateOptions

			if @currentView
				p = @currentView.__proto__ or @currentView #@currentView is for ie10
				if p and p.constructor and p.constructor is viewClass # update
					#update existing view
					if @currentView.state
						if updateOptions.clearState
							@currentView.state
							.clear silent: true
							.set @currentView.state.defaults, silent:true
						@currentView.state.set viewOptions
						return @currentView
				else # show
					view = new viewClass viewOptions
					@show view
					view
			else
				#create new view
				view = new viewClass viewOptions
				@show view
				view

		initAnimationBehavior: =>
			show = @show
			return false unless show
			@show = (view) =>
				destroyView = view.destroy
				view.destroy = =>
					new Promise (resolve, reject) =>
						destroyArgs = arguments
						durationMs = 1000 * Math.max(
							parseFloat(@$el.css('animation-duration')),
							parseFloat(@$el.css('transition-duration'))
						)
						@$el.removeClass('is-visible')
						defer = =>
							resolve destroyView.apply view, destroyArgs
						setTimeout defer, durationMs+5

				show.apply @, arguments
				defer = =>
					@$el.addClass 'is-visible'
				setTimeout defer, 5

		hide: =>
			@$el.removeClass 'is-visible'

		isVisible: =>
			@$el.hasClass 'is-visible'