@Iconto.module 'shared.views.wizard', (Wizard) ->
	class Wizard.WizardRegion extends Marionette.Region

		config:
			views: {}

		#example
#		config:
#			root: 'view1'
#			views:
#				view1:
#					viewClass: PathToView1Class
#         args: [arg1, arg2...] #passed to viewClass constructor
#					transitions:
#						transition1: 'view2'
#				view2:
#					viewClass: PathToView2Class
#					transitions:
#						transition2: 'view3'
#				view3:
#					viewClass: PathToView3Class
#					transitions:
#						transition3: =>
#							#do some additional logic
#							#manually call transition
#							@transition 'view1'

		initialize: =>
			@config = Marionette.getOption @, 'config'
			#config can be a function
			@config = if _.isFunction(@config) then @config() else @config
			#each view entry can be a function also
			@config[viewKey] = @config[viewKey]() for viewKey, view of @config when _.isFunction(view)
			#initial
			rootViewKey = @config.root
			@transition rootViewKey if rootViewKey

		transition: (viewKey) =>
			#stop listening currentView
			@stopListening @currentView if @currentView

			#create new instance of destination view
			view = @config.views[viewKey]

			throw new ObjectError("Could not find viewClass for view '#{viewKey}'") unless view.viewClass

			args = _.result view, 'args'
			if not args
				args = []
			else
				args = [args] unless _.isArray args
			args.unshift view.viewClass #context
			#dynamically apply view constructor with passed args
			instance = new (Function::bind.apply view.viewClass, args) #android < 4 does not support bind - use shim

			#start listening
			for transition, destinationViewKey of view.transitions
				do (transition, destinationViewKey) =>
					@listenTo instance, "transition:#{transition}", =>
						#use can specify callback instead of destinationViewKey
						if _.isFunction(destinationViewKey)
							destinationViewKey.apply @, arguments #pass transition arguments to callback
#							destinationViewKey.call @
						else
							@transition destinationViewKey

			#render
			@show instance


