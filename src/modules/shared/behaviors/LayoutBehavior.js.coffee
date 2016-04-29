@Iconto.module 'shared.behaviors', (Behaviors) ->
	class Behaviors.Layout extends Marionette.Behavior # TODO: rename
		defaults:
			template: null
			outlets:
				topbar: JST['shared/templates/topbar']
				breadcrumbs: JST['shared/templates/breadcrumbs']

		ui:
			_topbar: '.topbar-region'

		initialize: =>
			return false if @options.template is false
			layoutTemplate = @options.template || JST['shared/templates/mobile-layout']

			self = @
			allOutlets = _.extend {}, @defaults.outlets, @options.outlets

			render = ->
				# from Marionette.CompositeView _renderTemplate
				data = this.serializeData();
				data = this.mixinTemplateHelpers(data);

				this.triggerMethod('before:render:template');
				template = this.getTemplate();
				#				html = Marionette.Renderer.render(template, data, this);

				_.extend data, outlet: (name) ->
					unless name
						#render self
#						html
						Marionette.Renderer.render(template, data, this)
					else
						#check if view's defined an outlet in behavior options' 'outlets' hash
						outlet = allOutlets[name]
						unless _.isNull(outlet) or _.isUndefined(outlet)
							if _.isFunction(outlet)
								#JST template
								Marionette.Renderer.render(outlet, data)
							else if _.isString(outlet)
								#raw string
								outlet
							else
								console.log "Behaviors.Layout: Outlet '#{name}' is not valid"

				layoutHtml = Marionette.Renderer.render(layoutTemplate, data)

				this.attachElContent(layoutHtml);
				this.bindUIElements();
				this.triggerMethod('render:template');

			if @view instanceof Marionette.CompositeView
				#override composite's view renderModel method only
				@view._renderTemplate = render
			else if @view instanceof Marionette.CollectionView
				throw "Layout behavior for Marionette.CollectionView is not supported yet"
			else if @view instanceof Marionette.ItemView
				#override whole render method
				@view.render = ->
					@isDestroyed = false

					@triggerMethod("before:render", @)

					@$el.html render.call(@)

					this.bindUIElements();

					this.triggerMethod("render", this);

					@

		onShow: =>
			_.defer @updateBottomPadding
			$(window).on 'resize.mobile-layout', _.debounce @updateBottomPadding, 300

		onBeforeDestroy: =>
			$(window).off 'resize.mobile-layout'
			if @view instanceof Marionette.CompositeView
				delete @view.renderModel
			else if @view instanceof Marionette.CollectionView
				throw "Layout behavior for Marionette.CollectionView is not supported yet"
			else if @view instanceof Marionette.ItemView
				delete @view.render

		updateBottomPadding : =>
			try
				return false if ( !@ui._topbar.length or !@view.$el.hasClass('mobile-layout') )
				tbh = unless @ui._topbar.is(':visible') then 0 else @ui._topbar.height()
				@view.$el.css 'padding-bottom', tbh
			catch err
				console.warn err