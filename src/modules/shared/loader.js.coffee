@Iconto.module 'shared', (Shared) ->
	class Shared.Loader extends Backbone.Router

		loaded = {}

		appendStyles = (css) ->
			$('head').append '<style class="module_styles">' + css + '</style>'

		@unload = (name) ->
			#TODO: remove js and css from page
			delete loaded[name]

		load: (name) => #recursive
			Q.fcall =>
				return false if loaded[name] #module is already loaded

				module = @config[name]
				console.info 'LOADER:', name, module.path, 'LOADING'
				Q.fcall =>
					if module.deps
						console.info 'LOADER:', name, module.path, 'LOADING DEPS'
						deps = (@load(dep) for dep in module.deps)
						return Q.all(deps).then =>
							console.info 'LOADER:', name, module.path, 'LOADED DEPS'
				.then =>
					#if there were any deps - they are all loaded
					head = document.getElementsByTagName('head')[0]

					# load js
					jsPromise = $.Deferred()
					if module.path.js
						script = document.createElement('script')
						script.id = name
						script.src = "#{document.location.protocol}//#{document.location.host}" + module.path.js
						script.type = "text/javascript"
						script.onload = ->
							jsPromise.resolve()
						script.onerror = ->
							jsPromise.reject()
						head.appendChild(script)

					# load css
					cssPromise = $.Deferred()
					if module.path.css
						link = document.createElement('link')
						link.id = name
						link.type = "text/css"
						link.rel = "stylesheet"
						link.href = "#{document.location.protocol}//#{document.location.host}" + module.path.css
						link.onload = ->
							cssPromise.resolve()
						link.onerror = ->
							cssPromise.reject()
						head.appendChild(link)

					Q.all([jsPromise, cssPromise])
					.then ([moduleJs, moduleCss]) =>
						loaded[name] = true
						console.info 'LOADER:', name, module.path, 'LOADED'
						true #successfully loaded

		configure: (@config) ->
			_.each @config, (module, name) =>
				unless module.route is undefined
					@route "#{module.route}(/*query)", "loader_#{name}", =>
						@load(name)
						.then (result) =>
							if Backbone.History.started
								Backbone.history.loadUrl() if result
							else
								Backbone.history.start()