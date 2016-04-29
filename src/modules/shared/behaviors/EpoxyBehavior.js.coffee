@Iconto.module 'shared.behaviors', (Behaviors) ->
	class Behaviors.Epoxy extends Marionette.Behavior
		defaults:
			state: true
			bindCollection: false
		uiBinded: false

		mixin:
			applyBindings: Backbone.Epoxy.View::applyBindings
			removeBindings: Backbone.Epoxy.View::removeBindings
			getBinding: Backbone.Epoxy.View::getBinding
			setBinding: Backbone.Epoxy.View::setBinding
			b: Backbone.Epoxy.View::b

		initialize: (options, view) =>
			if @options.state
				view.state = new Backbone.Model() unless view.state
				#extend bindingSources
				if _.isFunction(view.bindingSources)
					old = view.bindingSources
					view.bindingSources = ->
						result = old.apply(view, arguments) || {}
						result.state = view.state
						result
				else
					view.bindingSources ||= {}
					view.bindingSources.state = -> view.state
			_.extend view, @mixin
			view.bindings ||= 'data-bind'
			view.setterOptions ||= {}
			_.extend view.setterOptions, Backbone.Epoxy.View::setterOptions, validate: true
			view.bindingHandlers ||= {}
			_.extend view.bindingHandlers, CustomBindingHandlers
			view.bindingFilters ||= {}
			_.extend view.bindingFilters, CustomBindingFilters

		onRender: =>
			unless @options.bindCollection
				#skip collection binding
				#use marionette's implementation
				collection = @view.collection
				@view.collection = null
				@view.applyBindings()
				@view.collection = collection
			else
				@view.applyBindings()

		onBeforeDestroy: =>
			@view.removeBindings()

	#				// Reads value from an accessor:
	#				// Accessors come in three potential forms:
	#				// => A function to call for the requested value.
	#				// => An object with a collection of attribute accessors.
	#				// => A primitive (string, number, boolean, etc).
	#				// This function unpacks an accessor and returns its underlying value(s).
	readAccessor = (accessor) ->
		if _.isFunction accessor
			return accessor()
		else if _.isObject accessor
			accessor = _.clone accessor
			_.each accessor, (value, key) ->
				accessor[key] = readAccessor value
		accessor

	Behaviors.CustomBindingHandlers = CustomBindingHandlers =
		hide: ($element, value) ->
			if !!value
				$element.hide()
			else
				$element.show()
		maskByValue:
			get: ($el, value, events) ->
				val = $el.val() - 0
				if $el.is(':checked')
					value + val
				else
					value - val
			set: ($el, value) ->
				val = $el.val() - 0
				value & val

#		value: #override default handler from Backbone.Epoxy to support [contenteditable]
#			get: ($element) ->
#				if $element.attr('contenteditable') is undefined
#					#non contenteditable
#					$element.val()
#				else
#					$element.html()
#			set: ($element, value) ->
#				if $element.attr('contenteditable') is undefined
#					if $element.val() != value
#						$element.val(value)
#				else
#					if $element.text() != value
#						$element.text(value)

		htmlToText:
			init: ($el, attrValue, bindings, context) ->
				@proxy = '';
				undefined
			get: ($element, event) ->
				@proxy = Iconto.shared.helpers.string.htmlToText $element.html()
			set: ($element, value) ->
				unless value is @proxy
					@proxy = value
					$element.text value

		html:
			get: ($element) ->
				$element.html()
			set: ($element, value) ->
				$element.html value unless $element.html() is value

		countryCode: ($el, value) -> value #goes with phone
		phoneValue:
			init: ($el, attrValue, context, bindings) ->
				@countryCode = bindings.countryCode
				undefined
			get: ($element, currentValue, event) ->
				countryCode = readAccessor(@countryCode)
				parsed = Iconto.shared.helpers.phone.parse($element.val())
				if parsed isnt ''
					"#{countryCode}#{parsed}"
				else
					''
			set: ($element, value, target) ->
				countryCode = readAccessor(@countryCode)
				cut = "#{value}".replace(new RegExp("^#{countryCode}"), '')

				#				parsed = Iconto.shared.helpers.phone.parse($element.val())
				parsed = Iconto.shared.helpers.phone.parse($element.val())

				unless cut is parsed
#					formatted = Iconto.shared.helpers.phone.format(cut)
					formatted = cut
					$element.val(formatted)

			clean: ->
				@countryCode = null

	#example how to pass additional parameters to handlers - escape: false
	#		escape: -> undefined #needed to appear in context
	#		escapedValue: #custom value handler with escaping support
	#			init: ($el, attrValue, bindings, context) ->
	#				if context.escape is false
	#					@escapeFn = (value) ->
	#						"#{value}".replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#x27;').replace(/\//g,'&#x2F;')
	#				undefined
	#			get: ($el, attrValue, event) ->
	#				$el.val()
	#			set: ($el, attrValue) ->
	#				result = if @escapeFn then @escapeFn attrValue else attrValue
	#				$el.val result
	#			clean: ->
	#				@escapeFn = null

		underscore:
			init: ($element, value, context) ->
				raw = $element.find('script,template')
				@t = _.template(if raw.length then raw.html() else $element.html())
				undefined
			set: ($element, value) ->
				value = if value instanceof Backbone.Model then value.toJSON({computed: true}) else value
				$element.html @t value
			clean: ->
				@t = null

		sodValue:
			get: ($element) ->
				$element.val()
			set: ($element, value) ->
				if $element.val() != value
					$element.val(value)
				$element.selectOrDie('select', value)

		options: do ->
			handler =
				init: ($element, value, context, bindings) ->
					@e = bindings.optionsEmpty
					@d = bindings.optionsDefault
					@v = bindings.value
					undefined

				set: ($element, value) ->
#					Pre-compile empty and default option values:
#					both values MUST be accessed, for two reasons:
#					1) we need to need to guarentee that both values are reached for mapping purposes.
#					2) we'll need their values anyway to determine their defined/undefined status.
					optionsEmpty = readAccessor(@e)
					optionsDefault = readAccessor(@d)
					currentValue = readAccessor(@v)
					options = if value instanceof Backbone.Collection then value.models else value
					numOptions = options.length
					enabled = true
					html = ''

					#					No options or default, and has an empty options placeholder:
					#					display placeholder and disable select menu.
					if not numOptions and not optionsDefault and optionsEmpty
						html += @opt optionsEmpty, numOptions
						enabled = false
					else
#						Try to populate default option and options list:

#						Configure list with a default first option, if defined:
						if optionsDefault
							options = [optionsDefault].concat options

						#						Create all option items:
						_.each options, (option, index) =>
							html += @opt option, numOptions

					#					Set new HTML to the element and toggle disabled status:
					$element.html(html).prop('disabled', !enabled).val(currentValue)

					#update sod
					unless $element.data('selectOrDieInitialized')
						$element.selectOrDie().data('selectOrDieInitialized', true)
					else
						$element.selectOrDie('update')

					if enabled
						$element.selectOrDie('enable')
					else
						$element.selectOrDie('disable')

					#					Pull revised value with new options selection state:
					revisedValue = $element.val()

					#					Test if the current value was successfully applied:
					#					if not, set the new selection state into the model.
					if @v and not _.isEqual currentValue, revisedValue
						@v revisedValue

			# you can render optgroups specifying them as {label: '', value: [.....]} (value is an array of options)
			# for options use supported notation (supported by Epoxy)
				opt: (option, numOptions) ->
#					Set both label and value as the raw option object by default:
					label = option
					value = option
					textAttr = 'label'
					valueAttr = 'value'

					#					Dig deeper into label/value settings for non-primitive values:
					if _.isObject option
#						Extract a label and value from each object:
#						a model's 'get' method is used to access potential computed values.
						label = if option instanceof Backbone.Model
							option.get textAttr
						else
							option[textAttr]

						value = if option instanceof Backbone.Model
							option.get valueAttr
						else
							option[valueAttr]

					if _.isArray value
						options = value.map(@opt).join('')
						"<optgroup label=\"#{label}\">#{options}</optgroup>"
					else
						"<option value=\"#{value}\">#{label}</option>"

				clean: ->
					@d = @e = @v = 0

	Behaviors.CustomBindingFilters = CustomBindingFilters =
		trim: (value) ->
			if value
				String::trim.call(value)
			else ""
		ignoreWhitespace: (value) ->
			value = value.replace(/\s/g, '')
		getField: (source, field) ->
			console.warn 'Epoxy filter getField is deprecated. Use get instead.'
			source[field]
		get: (source, field) ->
			_.get(source, field)
		getDateStringFromUnixTime: (time) ->
			if !!!time then return ""
			d = new Date(time * 1000)
			day = d.getDate()
			month = d.getMonth() + 1
			year = d.getFullYear()
			day = "0#{day}" if day < 10
			month = "0#{month}" if month < 10
			return "#{year}-#{month}-#{day}"
		number: (value) ->
			parsed = parseInt(value)
			`value == parsed ? parsed : value`
		declension: Iconto.shared.helpers.declension
		distance: Iconto.shared.helpers.distance.format
		getDateString: Iconto.shared.helpers.datetime.getDateString
		money: Iconto.shared.helpers.money
		phoneFormat7: Iconto.shared.helpers.phone.format7
		replace: (source, regexp, replaceString) ->
			if source and source.replace and regexp
				flags = regexp.substr(regexp.lastIndexOf('/') + 1)
				regexp = regexp.replace(/^\/|\/.$/g, '')
				source.replace new RegExp(regexp, flags), replaceString
			else
				source
		phone:
			get: (value) ->
				value.replace /^7(\d{10})$/, '$1'
			set: (value) ->
				value = value.replace /[\(,\),\-, ]/g, ''
				if value.length is 10 then "7#{value}" else value
		intToBool:
			get: (value) ->
				if value is 0 then false else true
			set: (value) ->
				if value then 0 else 1
		equal: (obj1, obj2) ->
			obj1 is obj2
		gt: (obj1, obj2) ->
			obj1 > obj2
		resize: Iconto.shared.helpers.image.resize
		calendar: (unixTime) ->
			moment.unix(unixTime).calendar()

		utcDate:
			get: (value) ->
				value = if value and _.isNumber(value)
					moment(value).format('YYYY-MM-DD')
				else ''
				value

			set: (value) ->
				value = if value and _.isString(value)
					+moment(value, 'YYYY-MM-DD')
				else 0
				value

		utcTime:
			get: (value) =>
				value = if value and _.isNumber(value)
					moment(value).format('HH:mm')
				else ''
				value

			set: (value) ->
				value = if value and _.isString(value)
					+moment(value, 'HH:mm')
				else 0
				value

		utcDateTime:
			get: (value) =>
				value = if value and _.isNumber(value)
					moment(value).format("YYYY-MM-DDTHH:mm")
				else ''
				value

			set: (value) ->
				value = if value and _.isString(value)
					+moment(value, "YYYY-MM-DDTHH:mm")
				else 0
				value

		utcMonth:
			get: (value) =>
				value = if value and _.isNumber(value)
					moment(value).format("YYYY-MM")
				else ''
				value

			set: (value) ->
				value = if value and _.isString(value)
					+moment(value, "YYYY-MM")
				else 0
				value

		unixDate:
			get: (value) ->
				value = if value and _.isNumber(value)
					moment.unix(value).format('YYYY-MM-DD')
				else ''
				value

			set: (value) ->
				value = if value and _.isString(value)
					+moment(value,'YYYY-MM-DD').unix()
				else 0
				value

		unixDateEndOfDay:
			get: (value) ->
				value = if value and _.isNumber(value)
					moment.unix(value).format('YYYY-MM-DD')
				else ''
				value

			set: (value) ->
				value = if value and _.isString(value)
					+moment(value,'YYYY-MM-DD').endOf('day').unix()
				else 0
				value

		unixTime:
			get: (value) =>
				value = if value and _.isNumber(value)
					moment.unix(value).format('HH:mm')
				else ''
				value

			set: (value) ->
				value = if value and _.isString(value)
					+moment(value, 'HH:mm').unix()
				else 0
				value

		unixDateTime:
			get: (value) =>
				value = if value and _.isNumber(value)
					moment.unix(value).format("YYYY-MM-DDTHH:mm")
				else ''
				value

			set: (value) ->
				value = if value and _.isString(value)
					+moment(value, "YYYY-MM-DDTHH:mm").unix()
				else 0
				value

		unixMonth:
			get: (value) =>
				value = if value and _.isNumber(value)
					moment.unix(value).format("YYYY-MM")
				else ''
				value

			set: (value) ->
				value = if value and _.isString(value)
					+moment(value, "YYYY-MM").unix()
				else 0
				value

		fileName:
			get: (value) =>
				if value and value.name then value.name else ''

		json:
			get: (value) =>
				console.log 'get',arguments
				value = if _.isArray(value) or _.isObject(value)
					JSON.stringify(value, null, '\t')
				else
					value+''
				value

		unicode:
			get: (value) ->
				Iconto.shared.helpers.toUnicode value

		toFixed:
			get: (value, fixTo) ->
				return "0" unless value
				if _.isString(value) then value-=0
				value.toFixed(fixTo)

		url:
			get: (value) ->
				Iconto.shared.helpers.navigation.parseUri(value).href

		empty:
			get: (value) ->
				_.isEmpty value