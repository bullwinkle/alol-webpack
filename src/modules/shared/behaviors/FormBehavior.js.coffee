@Iconto.module 'shared.behaviors', (Behaviors) ->
	class Behaviors.Form extends Marionette.Behavior

		EVENT_NAMESPACE = 'form-behavior-submit-event'

		defaults:
			submit: '' #string selector
			events: {}
		#eventName: 'selector' #for example events: {submit: 'form', click: '[name=submit]'}
			mixin: false #extend binding source with validation mixin - do not extend by default
			handler: 'onFormSubmit' #default handler
			validated: ['model'] #default list of validated model-names

		initialize: =>
			@view.setterOptions ||= {}
			delete @view.setterOptions['validate']

		onRender: =>
			events = @options.events
			throw new Error 'No events specified for FormBehavior' if _.isEmpty events

			@sources = {}
			@options.validated.forEach (modelName) =>
				@sources[modelName] = _.result @view, modelName

			for event, selector of events
				@view.$el.on "#{event}.#{EVENT_NAMESPACE}", selector, @onSubmitEvent

			for key, source of @sources
				_.extend source, Backbone.Validation.mixin if @options.mixin
				Backbone.Validation.bind @, model: source
			undefined

		onSubmitEvent: (e) =>
			return true if @onSubmitEventLock
			@view.setterOptions.validate = true
			sources = _.toArray(@sources)
			source.validate?() for source in sources #try to execute 'validate' method on each source if the method exists
			validator = (s) ->
				if s.isValid
					isValid = s.isValid()
					unless isValid
						console.warn "invalid: #{_.get(s,'constructor.name')}", _.result(s,'getInvalidFields')
					return isValid
				else true #if source has 'isValid' method then return its result, otherwise source is valid by default
			if _.every(sources, validator)
				@onSubmitEventLock = true
				submit = @options.submit
				@view.$(submit).addClass 'is-loading' if submit
				Q.fcall =>
					@view[@options.handler]?.call @view, e
				.done =>
					@view.$(submit).removeClass 'is-loading' if submit
					@onSubmitEventLock = false
			undefined

		onBeforeDestroy: =>
			for key, source of @sources
				Backbone.Validation.unbind(@, model: source)
				delete @sources[key]

			for event of @options.events
				@view.$el.off "#{event}.#{EVENT_NAMESPACE}"


	#		defaults:
	#			showLoading: true
	#			preventSubmit: true
	#			hideFirstValidation: true

	#		events:
	#			'submit form': 'onFormSubmit'
	#			'submit': 'onFormSubmit' #if current view is a form itself

	#		modelEvents:
	#			'validated:valid': 'onModelValid'
	#			'validated:invalid': 'onModelInvalid'

	#		onModelValid: ->
	#			@$('button[type=submit]').removeAttr 'disabled'

	#		onModelInvalid: ->
	#			@$('button[type=submit]').attr 'disabled', true

	#		onRender: =>
	#			if @options.hideFirstValidation
	#				if @view.$el.is('form')
	#					$form = @view.$el
	#				else
	#					$form = @view.$('form')
	#				unless $form.hasClass('hide-validation-errors')
	#					$form.addClass 'hide-validation-errors'
	#					$form.delegate 'input, textarea', 'focusin.first-validation', (e) =>
	#						$form.removeClass 'hide-validation-errors'
	#						$form.undelegate 'input', 'focusin.first-validation'
	#			Backbone.Validation.bind @view
	#
	#		onFormSubmit: (e) ->
	#			if @options.preventSubmit
	#				e.preventDefault()
	#
	#		onValidatedFormUpdate: (data) ->
	#			TODO: refactoring
	#			if data.field
	#				field = data.field.split('.')[1]
	#				temp = {}
	#				temp[field] = 'INVLID DATA ' + field
	#				@view.model.trigger 'validated:invalid', @view.model, temp
	#				Backbone.Validation.callbacks.invalid.call @view, @view, field, temp[field], 'name'


	_.extend Backbone.Validation.callbacks,
		valid: (view, attr, selector) ->
			$el = view.$("[#{selector}=\"#{attr}\"]")
			$el = $el.parent() unless $el.data('selectOrDie') is undefined
			$el.removeClass('has-validation-error').next('.validation-error').remove()

		invalid: (view, attr, error, selector) ->
			$el = view.$("[#{selector}=\"#{attr}\"]")
			$el = $el.parent() unless $el.data('selectOrDie') is undefined
			next = $el.next('.validation-error')
			unless next.get(0)
				$('<div></div>').text(error).addClass('validation-error').insertAfter $el.addClass 'has-validation-error'
			else
				next.text(error)
	#			console.log 'invalid field', selector, attr, error, view

	Backbone.Validation.configure
		forceUpdate: true
		selector: 'name'

	`
		//taken from Backbone.Validation
		var formatFunctions = {
			// Uses the configured label formatter to format the attribute name
			// to make it more readable for the user
			formatLabel: function (attrName, model) {
				return defaultLabelFormatters[defaultOptions.labelFormatter](attrName, model);
			},

			// Replaces nummeric placeholders like {0} in a string with arguments
			// passed to the function
			format: function () {
				var args = Array.prototype.slice.call(arguments),
						text = args.shift();
				return text.replace(/\{(\d+)\}/g, function (match, number) {
					return typeof args[number] !== 'undefined' ? args[number] : match;
				});
			}
		};

		_.extend(Backbone.Validation.validators, {
			size: function (value, attr, size, model) {
				if (!(_.isArray(value) && value.length == size)) {
					return formatFunctions.format(Backbone.Validation.messages.size, attr, size);
				}
			},
			minSize: function (value, attr, minValue, model) {
				if (!(_.isArray(value) && value.length >= minValue)) {
					return formatFunctions.format(Backbone.Validation.messages.minSize, attr, minValue);
				}
			},
			maxSize: function (value, attr, maxValue, model) {
				if (!(_.isArray(value) && value.length <= maxValue)) {
					return formatFunctions.format(Backbone.Validation.messages.maxSize, attr, maxValue);
				}
			},
			minUnixDate: function (value, attr, minValue, model) {
				var momentValue = moment(value);
				if (!(momentValue.isValid() && moment(minValue).isBefore(momentValue))) {
					return formatFunctions.format(Backbone.Validation.messages.minUnixDate, attr, minValue)
				}
			},
			maxUnixDate: function (value, attr, maxValue, model) {
				var momentValue = moment(value);
				if ((momentValue.isValid() && moment(maxValue).isBefore(momentValue))) {
					return formatFunctions.format(Backbone.Validation.messages.maxUnixDate, attr, maxValue)
				}
			},
			minUnixTime: function (value, attr, minTime, model) {
				var min = moment(minTime, 'HH:mm');
				var val = moment(value, 'HH:mm');
				if (val <= min) {
					return formatFunctions.format(Backbone.Validation.messages.time24, attr, minTime)
				}
			},
			maxUnixTime: function (value, attr, maxTime, model) {
				var max = moment(maxTime, 'HH:mm');
				var val = moment(value, 'HH:mm');
				if (val >= max) {
					return formatFunctions.format(Backbone.Validation.messages.time24, attr, maxTime)
				}
			},
			luhn: function (cardNumber, attr, validValue, model) {
				var cardNumberRegExp = new RegExp(/^\d{12,19}$/);
				var validateLuhn = Iconto.shared.helpers.card.validateLuhn

				if (!(cardNumberRegExp.test(cardNumber) && validateLuhn(cardNumber))) {
					return Backbone.Validation.messages.cardNumber
				}
			},
			snils: function (value) {
				// value stands for "12345678987", 11 digits
				var checkSum = parseInt(value.slice(9), 10);
				//строка как массив(для старых браузеров)
				value = "" + value;
				value = value.split('');
				var sum = (value[0] * 9 + value[1] * 8 + value[2] * 7 + value[3] * 6 + value[4] * 5 + value[5] * 4 + value[6] * 3 + value[7] * 2 + value[8] * 1);

				if (sum < 100 && sum == checkSum) {
					return undefined;
				} else if ((sum == 100 || sum == 101) && checkSum == 0) {
					return undefined;
				} else if (sum > 101 && (sum % 101 == checkSum || (sum % 101 == 100 && checkSum == 0))) {
					return undefined;
				} else {
					return "Неверный номер СНИЛС";
				}
			},
			inn: function (value) {
				//преобразуем в строку
				value = "" + value;
				//преобразуем в массив
				value = value.split('');
				//для ИНН в 10 знаков
				if ((value.length == 10) && (value[9] == ((2 * value[0] + 4 * value[1] + 10 * value[2] + 3 * value[3] + 5 * value[4] + 9 * value[5] + 4 * value[6] + 6 * value[7] + 8 * value[8]) % 11) % 10)) {
					return undefined;
					//для ИНН в 12 знаков
				} else if ((value.length == 12) && ((value[10] == ((7 * value[0] + 2 * value[1] + 4 * value[2] + 10 * value[3] + 3 * value[4] + 5 * value[5] + 9 * value[6] + 4 * value[7] + 6 * value[8] + 8 * value[9]) % 11) % 10) && (value[11] == ((3 * value[0] + 7 * value[1] + 2 * value[2] + 4 * value[3] + 10 * value[4] + 3 * value[5] + 5 * value[6] + 9 * value[7] + 4 * value[8] + 6 * value[9] + 8 * value[10]) % 11) % 10))) {
					return undefined;
				} else {
					return "Неверный номер ИНН";
				}
			},
			ogrn: function (value) {
				//для ОГРН в 13 знаков
				if (value.length == 13 && (value.slice(-1) == ((value.slice(0, -1)) % 11 + '').slice(-1))) {
					return undefined;
					//для ОГРН ИП в 15 знаков
				} else if (value.length == 15 && (value.slice(-1) == ((value.slice(0, -1)) % 13 + '').slice(-1))) {
					return undefined;
				} else {
					return "Неверный номер ОГРН";
				}
			}
		})
		;
		_.extend(Backbone.Validation.patterns, {
			// email contains only latin symbols
			email: /^([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x22([^\x0d\x22\x5c\x80-\xff]|\x5c[\x00-\x7f])*\x22)(\x2e([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x22([^\x0d\x22\x5c\x80-\xff]|\x5c[\x00-\x7f])*\x22))*\x40([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x5b([^\x0d\x5b-\x5d\x80-\xff]|\x5c[\x00-\x7f])*\x5d)(\x2e([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x5b([^\x0d\x5b-\x5d\x80-\xff]|\x5c[\x00-\x7f])*\x5d))*$/, //http://stackoverflow.com/questions/4320574/why-is-jquerys-email-validation-regex-so-simple
			phone: /^7\d{10}$/,
			time24: /^((([01]?[0-9]|2[0-3]):[0-5][0-9])|24:00)$/,
			unixDate: /^\d{4}\-[0-1][0-9]\-[0-3][0-9]$/,
			cardNumber: /^\d{12}|\d{19}$/,
			cardNumber2: /^\d{12,19}$/
		});
	`

	_.extend Backbone.Validation.messages,
		acceptance: "Обязательное поле"
		digits: "Допустимы только цифры"
		email: "Неверный адрес электронной почты"
		equalTo: "Значения не равны"
		inlinePattern: "Неверное значение"
		length: "Допустимая длина: {1}"
		max: "Максимальное значение: {1}"
		maxLength: "Максимальная длина: {1}"
		min: "Минимальное значение: {1}"
		minLength: "Минимальная длина: {1}"
		number: "Неверное число"
		oneOf: "Неверное значение"
		pattern: "Неверное значение"
		range: "Значение должно быть в промежутке от {1} до {2}"
		rangeLength: "Длина должна быть в промежутке от {1} до {2}"
		required: "Обязательное поле"
		url: "Неверный адрес"
		size: "Допустимое количество: {1}"
		minSize: "Минимальное количество: {1}"
		maxSize: "Максимальное количество: {1}"
		phone: "Неверный номер телефона"
		time24: "Неверное время"
		unixDate: "Неверная дата"
		minUnixDate: "Неверная дата" #TODO: replace error text
		maxUnixDate: "Неверная дата"
		cardNumber: "Неверный номер карты"

