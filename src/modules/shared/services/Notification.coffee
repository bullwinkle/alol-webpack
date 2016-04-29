@Iconto.module 'shared.services', (Services) ->
	# Standartize notification api for both Web Notifications and Alertyfy notifications
	alertify = window.alertify
	Notify = window.Notify

	#n instanceof Object - alertify
	#n instanceof Notify - Notify

	class NotificationsQueue extends Array
		constructor: ->
			super

		push: =>
			super


	###
	@abstract update visible notification, notification object must have 'update' method
	@param n [Object] notification object
	@param data [Object] object with new properties for notification
	@return result [Boolean] success or not
	###
	updateExistingNotification = (n = {}, data = {}) ->
		unless n.update
			console.warn "notification need to have own method 'update'"
			return false
		switch _.get n, 'constructor.name'
			when 'Object'
				try
					n.update data
					return true
				catch err
					console.warn err
					return false
			when 'Notify'
				try
					n.update data
					return true
				catch err
					console.warn err
					return false
			else
				return false

	class Notification
		@ENV_ALL = ENV_ALL = 'all'
		@ENV_PAGE = ENV_PAGE = 'page'
		@ENV_OS = ENV_OS = 'os'

		filters = {}
		###
		filter in format:
		{
			"foo.bar.baz": 'some value'
			...
		}

		blocks notification with options:
		{
			title: 'title',
			foo: {
				bar: {
					baz: 'some value'
				}
			}
		}
		###

		constructor: ->
			@ENV_ALL = Notification.ENV_ALL
			@ENV_PAGE = Notification.ENV_PAGE
			@ENV_OS = Notification.ENV_OS
			@notificationsQueue = new NotificationsQueue()
			Object.defineProperties @,
				###
				@abstract check if page tab is visible
				@return [Boolean] visible or not
				###
				pageVisible:
					get: -> if Modernizr.pagevisibility then !document.hidden else true

				###
				@return [Object] private immutable object filters
				###
				filters:
					get: -> filters

		###
		@abstract block displaying notifications for specified params and env. By setting env you can controll will notification will block in browser or outside
		@param key [String] required; key path to value to filter by
		@param options [object] required; key path to value to filter by
		@option value [Mixed] value to filter by
		@option env	[String] valid values are: 'all' | 'page' | 'os', default is 'all'
		@example block notifications with {data: { foo: 'bar' }} only when trying to show by user`s OS
			notificator = new Notification();
			notificator.setFilter('data.foo', {
				value: 'bar',
				env: 'os'
			});
		###
		setFilter: (key, {value, env}) =>
			return false unless _.isString key
			env ||= ENV_ALL
			filters[key] =
				value: value
				env: env

		###
		@abstract remove messages filter
		@param key [String] key to remove from filters
		###
		unsetFilter: (key) =>
			delete filters[key]

		###
		@abstract testing message options to decide, blocked it by filters or not
		@param key [String] key to remove from filters
		@return [Boolean] blocked or not
		###
		testOptions: (options, env = ENV_ALL) =>
			for filterKey, filter of filters
				filter ||= {}
				filterForCurrentEnv = filter.env is env
				filterForCurrentOptions = _.get(options, filterKey) is filter.value
				if filterForCurrentEnv and filterForCurrentOptions
					return false
			return true

		###
		@abstract decide, visible page or not, then if visible - show notification on page (notifyPage) , else outside of the browser (notifyOS)
		@param options [String, Object] if type of options is String, this string will be a title
 		@option title [String] required
		@option body [String]
		@option icon [String] absolute or relative url to icon in .png or .jpg
		@option tag [String, Number]
		@option timeout [Number] time in seconds
		@option data [Mixed] any data you need that will be attached to notification object
		@option onClick [Callback] callback will be called when notification was clicked
		@option onClose [Callback] callback will be called when notification closes automatically
		###
		notify: (options = {}) =>
			if _.isString(options) then options = {title: options + ''}

			_.defaultsDeep options,
				title: ''
				body: ''
				icon: '/apple-touch-icon.png'
				tag: Date.now()
				timeout: 3 # sec
				data: {}
				onClick: -> return true
				onClose: -> return true

			return false unless @testOptions options, ENV_ALL

			notification = null
			activeNotification = null

			if @pageVisible
				activeNotification = _.findLast @notificationsQueue, (n, i) ->
					return false unless n instanceof Object
					_.get(n, 'options.tag') is options.tag
				if activeNotification
					activeNotification.update options
					notification = activeNotification
				else
					notification = @notifyPage options
					@notificationsQueue.push notification
			else
				activeNotification = _.findLast @notificationsQueue, (n, i) ->
					return false unless n instanceof Notify
					_.get(n, 'options.tag') is options.tag
				if activeNotification
					activeNotification.update options
					notification = activeNotification
				else
					notification = @notifyOS options
					@notificationsQueue.push notification

			notification

		###
		@abstract show notification inside your page
		@param options [String, Object] if type of options is String, this string will be a title
 		@option title [String] required
		@option body [String]
		@option icon [String] absolute or relative url to icon in .png or .jpg
		@option tag [String, Number]
		@option timeout [Number] time in seconds
		@option data [Mixed] any data you need that will be attached to notification object
		@option onClick [Callback] callback will be called when notification was clicked
		@option onClose [Callback] callback will be called when notification closes automatically
		###
		notifyPage: (options = {}) =>
			if _.isString(options) then options = {title: options + ''}

			_.defaultsDeep options,
				title: ''
				body: ''
				icon: ''
				tag: Date.now()
				timeout: 0
				data: {}
				onClick: -> return true
				onClose: -> return true

			return false unless @testOptions options, ENV_PAGE

			activeNotification = _.findLast @notificationsQueue, (n, i) ->
				return false unless n instanceof Object
				_.get(n, 'options.tag') is options.tag
			if activeNotification
				activeNotification.update options
				return activeNotification
			else
				notificationContent = JST['shared/templates/notifications/chat-message'](options)
				notification = alertify.notify notificationContent, 'chat-new-message', options.timeout
				@notificationsQueue.push notification

				notification.callback = (clicked) =>
					console.info "browser notification dismissed by #{if clicked then 'user' else 'timer'}"
					if clicked
						_.result options, 'onClick'
					else
						_.result options, 'onClose'

					_.remove @notificationsQueue, notification

				close = notification.dismiss
				show = notification.push

				notification.options = options
				notification.show = =>
					show.apply notification, arguments
				notification.close = =>
					close.apply notification, arguments
					_.remove @notificationsQueue, notification
				notification.update = (newOptions) =>
					if _.isString(newOptions) then newOptions = {title: newOptions + ''}
					_.pick newOptions, ['title', 'body', 'icon', 'timeout']
					newOptions = _.extend notification.options, newOptions
					newNotificationContent = JST['shared/templates/notifications/chat-message'] _.pick(newOptions,
						['title', 'body', 'icon'])
					notification.setContent newNotificationContent
					notification.delay newOptions.timeout
					notification.show()
					notification
				notification.data = options.data

				return notification

		###
		@abstract show notification outside of the browser
		@param options [String, Object] if type of options is String, this string will be a title
 		@option title [String] required
		@option body [String]
		@option icon [String] absolute or relative url to icon in .png or .jpg
		@option tag [String, Number]
		@option timeout [Number] time in seconds
		@option data [Mixed] any data you need that will be attached to notification object
		@option onShow [Callback] callback will be called when notification shows
		@option onClick [Callback] callback will be called when notification was clicked
		@option onClose [Callback] callback will be called when notification was closed
		@option onError [Callback] callback will be called when notification closes automatically
		###
		notifyOS: (options = {}) =>
			if _.isString(options) then options = {title: options + ''}

			# inject window.focus() to onClick handler
			# to open current browser tab from anywhere
			if _.isFunction options.onClick
				onClickSafe = options.onClick
				options.onClick = ->
					window.focus()
					onClickSafe()

			_.defaultsDeep options,
				title: 'АЛОЛЬ'                                          # required (string) - notification title
				body: ''                                                    #(string) - notification message body
				icon: '/apple-touch-icon.png'                            #(string) - path for icon to display in notification
				tag: Date.now()                                            #(string) - unique identifier to stop duplicate notifications
				timeout: 0                                               #(integer) - number of seconds to close the notification automatically
				lang: 'ru'                                                #(string) - BCP 47 language tag for the notification (default: en)
				data: {}
				onShow: () =>
					console.info 'OS notification onShow', arguments
				onClose: () =>
					console.info "OS notification closed", arguments
				onClick: () =>
					console.info "OS notification clicked", arguments
				onError: () =>
					console.info 'OS notification onError', arguments

			return false unless @testOptions options, ENV_OS

			options = _.mapKeys options, (value, key) ->
				switch key
					when 'onShow' then 'notifyShow'
					when 'onClose' then 'notifyClose'
					when 'onClick' then 'notifyClick'
					when 'onError' then 'notifyError'
					else
						key

			notification = new Notify options.title, _.omit(options, 'title')

			activeNotification = _.findLast @notificationsQueue, (n, i) ->
				return false unless n instanceof Notify
				_.get(n, 'options.tag') is options.tag
			if activeNotification
				activeNotification.update options
				return activeNotification
			else
				notification = new Notify options.title, _.omit(options, 'title')
				@notificationsQueue.push notification

				showNotification = =>
					notification.show()

				onPermissionDenied = =>
					console.warn 'User declined notifications OS notifications'

				if (!Notify.needsPermission)
					showNotification()
				else if (Notify.isSupported())
					Notify.requestPermission(showNotification, onPermissionDenied)

				close = notification.close
				show = notification.show
				onClick = notification.onClickCallback
				onClose = notification.onCloseCallback

				notification.onClickCallback = =>
					onClick.apply notification, arguments
					close.apply notification, arguments
					_.remove @notificationsQueue, notification
				notification.onCloseCallback = =>
					onClose.apply notification, arguments
					_.remove @notificationsQueue, notification
				notification.show = =>
					show.apply notification, arguments
				notification.close = =>
					close.apply notification, arguments
					_.remove @notificationsQueue, notification
				notification.update = (newOptions) =>
					if _.isString(newOptions) then newOptions = {title: newOptions + ''}
					_.extend notification.options, _.pick(newOptions, ['body', 'icon', 'lang', 'timeout'])
					if newOptions.title
						notification.title = newOptions.title
					notification.show()
					notification
				notification.data = options.data

				return notification

	Services.Notification = Notification