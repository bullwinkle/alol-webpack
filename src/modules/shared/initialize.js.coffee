window.Iconto ||= {}
_.extend window.Iconto,
	behaviors: {}
	models: {}
	REST: {}
	templates: {}
	views:
		modals: {}
		wallet: {}
		office: {}
		landing: {}

window.ICONTO_API_SID ||= 'iconto_api_sid'
window.ICONTO_API_URL ||= 'https://dev.alol.io/rest/2.0/'

window.ICONTO_WEBSOCKET_URL ||= '//dev.alol.io/'
window.ICONTO_WEBSOCKET_PORT ||= 4444
window.ICONTO_WEBSOCKET_SECURE_PORT ||= 4445

window.ICONTO_TRANSPORTS =
	HTTP: 'HTTP'
	WEBSOCKET: 'WEBSOCKET'
window.ICONTO_CURRENT_TRANSPORT ||= window.ICONTO_TRANSPORTS.HTTP

window.JST ||= {}

window.Iconto.module = (path, callback) ->
	parts = path.split('.')
	current = @
	for key in parts
		current[key] ||= {}
		current = current[key]
	callback?.call @, current #do not imitate Marionette.Module arguments passing (App, Marionette, Backbone...)

#@Iconto.vent = new Marionette.EventAggregator()
window.Iconto.commands = new Backbone.Wreqr.Commands()
window.Iconto.events = new Backbone.Wreqr.EventAggregator()

window.ObjectError = (data) ->
	if data instanceof Error
		return data
	else
		return _.extend new Error(JSON.stringify(data)), data

window.crypto = window.crypto || window.msCrypto

#vendor initialization
window.Q = ->
	Promise.cast.apply(@, arguments).cancellable()
for method in ['all', 'any', 'props', 'settle', 'race', 'some', 'map', 'reduce', 'filter', 'each', 'delay', 'try']
	do (method) ->
		Q[method] = -> Promise[method].apply(@, arguments).cancellable()
Q.fcall = Q['try']

Marionette.Behaviors.behaviorsLookup = ->
	Iconto.shared.behaviors

#$.cookie.defaults.path = '/'

Q.longStackSupport = true

$.fn.scrollToTop = ->
	$(@).scrollTop 0

$.fn.scrollToBottom = ->
	$(@).scrollTop $(@).prop('scrollHeight') or 9999999

(($) ->
	$.fn.serializeObject = ->
		o = {}
		a = @serializeArray()
		$.each a, ->
			if o[@name]
				if !o[@name].push
					o[@name] = [o[@name]]
				o[@name].push @value or ''
			else
				o[@name] = @value or ''
			return
		o)(jQuery)

(($) ->
	$.fn.disableButton = ->
		if @hasClass('button') or @prop("tagName").toLowerCase() is "button"
			@addClass('is-loading').prop('disabled', true)
			return @
		else
			throw new Error("Element is not a button.")
)(jQuery)

(($) ->
	$.fn.enableButton = ->
		if @hasClass('button') or @prop("tagName").toLowerCase() is "button"
			@removeClass('is-loading').prop('disabled', false)
			return @
		else
			throw new Error("Element is not a button.")
)(jQuery)

(($) ->
	$.fn.contentTabs = () ->
		switchTab = (e,hash) ->
			return false if !e and !hash
			if e then $currentTab = $(e.currentTarget)
			else if hash
				$currentAnchor = @find("[href=#{hash}]")
				$currentTab = if $currentAnchor.hasClass('.tab-title')
					$currentAnchor
				else $currentAnchor.parents('.tab-title').eq(0)
			return false unless $currentTab.length

			$contents = $currentTab.parents('.tabs').siblings().closest('.tabs-content').find('.content')
			href = $currentTab.attr('href') or $currentTab.find('[href]').eq(0).attr('href')

			$currentTab.parents('.tabs').find('.tab-title').removeClass('active')
			$currentTab.addClass('active')
			$contents.removeClass('active').closest(href).addClass('active')
		switchTab.call @, null, window.location.hash
		@on 'click', '.tab-title', switchTab.bind @

)(jQuery)

_.templateSettings =
	escape: /<@-([\s\S]+?)@>/g
	evaluate: /<@([\s\S]+?)@>/g
	interpolate: /<@=([\s\S]+?)@>/g

`
	Backbone.Collection.prototype.findLast = function (predicate) {
		for (var i = this.models.length; i > 0; i--) {
			if (predicate(this.models[i - 1])) {
				return this.models[i - 1];
			}
		}
	};
`
# init global jQuery event handlers
$html = $('html')
$html
.on 'click', 'a[href=#]', (e) =>
	e.preventDefault()

.on 'click', 'a[href]:not([data-bypass]):not([href^=#])', (e) =>
	e.preventDefault()
	Iconto.shared.router.navigate $(e.currentTarget).attr('href'), trigger: true

.on 'click', 'a[href=#]', (e) =>
	e.preventDefault()

.on 'submit', 'form:not([action])', (e) =>
	e.preventDefault()

.on 'input paste change', 'div[contenteditable]', (e) =>
	$target = $(e.currentTarget)
	$target.empty() if $target.text().length is 0
	undefined

# material popup
# popup`s parent must have NON STATIC position
.on 'click', 'body', (e) ->
	unless $(e.target).hasClass('drop-down')
		$('.drop-down.open').removeClass('open')
.on 'click', '.drop-down',  (e) ->
	e.stopPropagation()
	$('.drop-down.open').removeClass('open')
	$(@).toggleClass('open')
.on 'click', '.drop-down li, .drop-down.open', (e) ->
	$this = $(@)
	if $this.hasClass('drop-down') and $this.hasClass('open')
		e.stopPropagation()
		$this.removeClass 'open'
	else
		$this.parents('.drop-down.open').removeClass('open')

.on('mouseleave', '.sod_list', (e) -> $(e.currentTarget).find('.active').removeClass('active'))
# fix stupid bug when click on nested to <label> element do not triggers click on actual <label> el
# select with selectOrDie need jQuery click to open
.on 'click touchstart', '[for]', (e) ->
	$this = $(@)
	toId = $this.attr 'for'
	$toEl = $ "#"+toId
	return true unless $toEl.length
	e.preventDefault()
	switch _.result($toEl, '[0].nodeName.toLowerCase')
		when 'input', 'textarea'
			switch $toEl.attr('type')
				when 'checkbox','radio'
					$toEl.trigger 'click'
				else
					$toEl.focus()
		else
			$toEl.trigger 'click'
	false

do ->
	input = document.createElement 'input'
	input.setAttribute 'type', 'date'

	Q.dispatch = (promise, view) ->
		throw new Error("Dispatch support only view instances") unless view instanceof Backbone.View
		view._promises ||= []
		cancellable = Q.try(-> promise).cancellable().catch (error) ->
			throw new ObjectError(error) unless error instanceof Promise.CancellationError
		view._promises.push cancellable
		cancellable

	Promise::dispatch = (view) ->
		Q.dispatch(@, view)

	Marionette.View::dispatch = (promise) ->
		Q.dispatch(promise, this)

	oldConstructor = Marionette.View
	Marionette.View = Marionette.View.extend
		constructor: ->
			oldConstructor.apply @, arguments

			@on 'render', =>
				unless input.type isnt 'text'       #TODO: load fdatepicker on demand
					#browser doesn't support input[type=date]
					#use datepicker instead
					@$('input[type=date]').each (index, input) =>
						$input = $(input)
						unless $input.data('datepickerInitialized')
							$input.attr('type', 'hidden').hide()
							$alt = $('<input type="text" readonly="true"/>').insertBefore($input)

							for key in ['class', 'style', 'min', 'max', 'data-date-format', 'data-date-language']
								value = $input.attr(key)
								$alt.attr(key, value) if value

							$alt.attr('data-is-datepicker', 'yes')
							$alt.attr('data-date-format', 'dd.mm.yyyy') unless $alt.attr('data-date-format')
							$alt.attr('data-date-language', 'ru') unless $alt.attr('data-date-language')

							$alt.show().fdatepicker weekStart: 1
							_.defer =>
								if $input.attr('value')
									$alt.fdatepicker 'setDate', new Date($input.attr('value'))
							$alt.on 'changeDate', (e) =>
								#change alt birthday date
								date = e.date
								if date
									month = "#{date.getMonth() + 1}"
									month = "0#{month}" if month.length is 1
									day = "#{date.getDate()}"
									day = "0#{day}" if day.length is 1
									value = "#{date.getFullYear()}-#{month}-#{day}"

									$input.val(value).change().trigger('input')
								else
									$input.val('').change().trigger('input')

							$input.data('datepickerInitialized', true)
				@$('select[data-select-or-die]').selectOrDie()
				#wheel scroll
				scrollable = '[data-scroll]'
				nonscrollable = '[data-prevent-scroll]'

				# 20 - 45 fps
				#$('body').on "mousewheel.#{@cid}", (e) =>
				#	unless $(e.target).closest(scrollable).get(0) or $(e.target).closest(nonscrollable).get(0)
				#		$scrollable = @$(scrollable).last()
				#		$scrollable.scrollTop($scrollable.scrollTop() - e.deltaY * e.deltaFactor)
				#	undefined

				# 40 - 60 fps
				$scrollable = @$(scrollable).last()
				$('body').on "mousewheel.#{@cid}", (e) =>
					return undefined unless $scrollable.length
					return undefined if $(e.target).closest(scrollable).get(0) or $(e.target).closest(nonscrollable).get(0)
					$scrollable.scrollTop($scrollable.scrollTop() - e.deltaY * e.deltaFactor)
					undefined

			@on 'before:destroy', =>
				$('body').off "mousewheel.#{@cid}"

				@_promises.pop().cancel() while @_promises.length > 0 if @_promises

				undefined

if alertify
	alertify
 	.set('notifier','position', 'top-right')
 	.set('notifier','delay', 1000)