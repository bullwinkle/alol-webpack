@Iconto.module 'office.views.offers', (Offers) ->

	NO_REAL_CONTRACT_MESSAGE = 'Для этих действий компания должна принять договор.'

	class CommonOfferModel extends Backbone.Model
		defaults:
			entityName: ''
			successSavedRoute: ''
			saveAndNotify: false
			notifyMessage: ''

	class CompanyTreatyAlert extends Iconto.shared.views.modals.Alert
		template: JST['office/templates/offers/cashback/company-treaty-alert']

	class Offers.BaseOfferEditView extends Marionette.LayoutView

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']
			Form:
				submit: '[name=save]'
				events:
					submit: 'form'

		regions: {}

		ui:
			topbarRightButton: '.topbar-region .right-small'
			topbarLeftButton: '.topbar-region .left-small'
			saveButton: '[name=save]'
			deleteButton: '[name=delete]'
			periodFromWrapper: '.period-from-wrapper'
			periodToWrapper: '.period-to-wrapper'
			period_from: '[name=period_from]'
			period_to: '[name=period_to]'
			saveAndNotify: '#save-and-notify'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
#			'submit form': 'onFormSubmit'
			'click @ui.deleteButton': 'onDeleteClick'
			'change .addresses .address input[type=checkbox]': 'onAddressCheck'
			'click @ui.uploadButton': 'uploadFiles'
			'click @ui.removeFIleButton': 'removeFile'

		modelEvents:
			'change:period_from': 'onChangePeriodFrom'
			'change:period_to': 'onChangePeriodTo'
			'change:worktime_from': 'checkWorktimeFrom'
#			'validated:valid': (mdoel, opts)-> console.info 'valid', opts
#			'validated:invalid': (mdoel, errors)-> console.warn 'invalid', errors

		validated: =>
			model: @model
			state: @state

		bindingSources: ->
			state: @state
			bank: @bank
			vm: @commonModel

		initialize: => # common initialize
			@commonModel = new CommonOfferModel
				notifyMessage: "Мы подготовили для вас новое предложение, смотри [[link]] !" # replace link with promo-feed link to this entity

			@state = new Iconto.office.models.StateViewModel @options
			@state.set
				isSaving: false

				addresses: []

				weekdays: 0

				monday: false
				tuesday: false
				wednesday: false
				thursday: false
				friday: false
				saturday: false
				sunday: false

		onRender: =>  # common onRender

		_updateRawWorktime: =>
			#parse and update state
			worktime = @model.get('work_time')
			for day, index in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
				@state.set day, worktime[index].length > 0, validate: @setterOptions.validate

			first = _.find worktime, (d) ->
				d.length > 0
			return false unless first

			@model.set
				worktime_from: moment().startOf('day').add('seconds', first[0][0]).format('HH:mm')
				worktime_to: if first[0][1] is 86399 then '23:59' else moment().startOf('day').add('seconds',
					first[0][1]).format('HH:mm')

		_updateModelWorktime: =>
			worktime = [
				[],
				[],
				[],
				[],
				[],
				[],
				[]
			]

			unless @state.isValid()
				@model.set 'work_time', worktime, validate: @setterOptions.validate
				return false

			state = @state.toJSON()

			worktimeFrom = @model.get('worktime_from')
			worktimeTo = @model.get('worktime_to')

			beginning = moment().startOf('day')
			from = moment(worktimeFrom, 'HH:mm')

			if worktimeTo is '24:00'
				to = moment('23:59:59', 'HH:mm:ss')
			else
				to = moment(worktimeTo, 'HH:mm')

			unless from.isValid() and to.isValid()
				@model.set 'work_time', worktime, validate: @setterOptions.validate
				return false

			from = from.diff(beginning, 'seconds')
			to = to.diff(beginning, 'seconds')

			for day, i in [state.monday, state.tuesday, state.wednesday, state.thursday, state.friday, state.saturday,
						   state.sunday]
				worktime[i].push [from, to] if day
			@model.set 'work_time', worktime, validate: @setterOptions.validate

		onChangePeriodFrom: (model, period_from, options) =>
			@ui.period_to.attr 'min', moment.unix(period_from).add('days',1).format('YYYY-MM-DD')

		onChangePeriodTo: (model, period_to, options) =>

		checkWorktimeFrom: =>
			_.extend @model.validation, #upgrade model's validation to take raw time values into account
				worktime_to:
					required: false
					pattern: 'time24'
					minUnixTime: @model.get 'worktime_from'

		newModelOnRender: =>
			@_updateRawWorktime()
			
		oldModelOnRender: (objectData) =>
			@_updateRawWorktime()

			@buffer = new @ModelClass @model.toJSON()
			@buffer.set objectData

		modelFetchingDone: =>
			@model.__fixedPreviousAttributes = @model.toJSON()
			periodFrom = @model.get('period_from')
			periodTo = @model.get('period_to')
			if periodFrom
				@ui.periodFromWrapper.find('[data-is-datepicker]').fdatepicker 'update', moment(periodFrom).format('DD.MM.YYYY')

			if periodTo
				@ui.periodToWrapper.find('[data-is-datepicker]').fdatepicker 'update', moment(periodTo).format('DD.MM.YYYY')

			thisMoment = moment()
			@ui.period_from.attr 'min', thisMoment.format('YYYY-MM-DD')
			@ui.period_to.attr 'min', thisMoment.add('days',1).format('YYYY-MM-DD')

			@state.set
				isLoading: false

		loadAddresses: =>
			(new Iconto.REST.AddressCollection()).fetchAll(company_id: @state.get('companyId'))
			.done (addresses) =>
				@state.set 'addresses': addresses
				@model.set 'address_ids', _.pluck(addresses, 'id') if @model.isNew()
				_.each @model.get('address_ids'), (id) =>
					@$(".addresses .address input[type=checkbox]#address_#{id}").attr 'checked', true

		onAddressCheck: (e) =>
			$target = $(e.currentTarget)
			checked = $target.is(':checked')
			$address = $target.closest('.address')
			id = $address.attr('data-id') - 0
			address_ids = _.clone(@model.get('address_ids'))
			if checked
				address_ids.push id unless id in address_ids
			else
				index = address_ids.lastIndexOf(id)
				address_ids.splice index, 1 if index isnt -1
			@model.set 'address_ids', address_ids, {validate: @setterOptions.validate }

		bindModelChangeWorkTimeEvents: =>
			#bind AFTER fetching model
			for attr in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'] #bind to state values
				@state.on "change:#{attr}", @_updateModelWorktime
			for attr in ['worktime_from',
						 'worktime_to'] #don't forget to bind to raw time values which are now in the model instead of the state
				@model.on "change:#{attr}", @_updateModelWorktime

		handleModelError: (error) =>
			error.msg = switch error.status
				when 103135
					"#{@commonModel.get('entityName')} не найден"
				when 103143
					NO_REAL_CONTRACT_MESSAGE
				else
					error.msg
			Iconto.shared.views.modals.ErrorAlert.show error
			route = @commonModel.get('successSavedRoute')
			Iconto.office.router.navigate route, trigger: true

		checkForTreaty: (company) ->
			return console.warn 'Company is not defined' unless company
			if company instanceof Backbone.Model
				accepted = !!company.get('is_real_contract')
			else
				accepted = !!company.is_real_contract
			unless accepted then Iconto.shared.views.modals.ErrorAlert.show
				message: NO_REAL_CONTRACT_MESSAGE
			accepted

		onDeleteClick: =>
			Iconto.shared.views.modals.Confirm.show
				title: 'Подтвердите удаление'
				message: "#{@commonModel.get('entityName')} нельзя будет восстановить!"
				onSubmit: =>
					@model.destroy()
					.then (response) =>
						route = @commonModel.get('successSavedRoute')
						Iconto.office.router.navigate route, trigger: true
					.catch (error) =>
						console.error error
						Iconto.shared.views.modals.ErrorAlert.show error
					.done()

		notifyUsers: (isNew) =>
			# get object`s feedId by pooling to generate link,
			# because of server problem:
			# feedItem entity is not ready right after creating or updating promotion/cashback entity
			console.log 'isNew', isNew
			return false unless @commonModel.get 'saveAndNotify'

			companyId = @state.get 'companyId'
			addresses = @state.get 'addresses'
			objectId = @model.get('id')
			objectType = @commonModel.get('objectType')
			objectTitle = @model.get 'title'

			getFeedItem = (cb) =>
				feedCollection = new Iconto.REST.PromoFeedCollection()
				.fetch
					object_id: objectId # need to be current ( updated ) id
					object_type: objectType
				.then (feedItems) =>
					feedId = _.get feedItems, '[0].id'
					cb(null, feedId)
				.dispatch(@)
				.catch (err) =>
					cb(err, null)
				.done()

			handleFeedId = (feedId) =>
				promotionLink = "#{window.location.origin}/wallet/offers"
				switch objectType
					when Iconto.REST.PromoFeed.OBJECT_TYPE_PROMOTION
						promotionLink += "/promotion"
					when Iconto.REST.PromoFeed.OBJECT_TYPE_CASHBACK
						promotionLink += "/cashbacks/#{companyId}"
				promotionLink += "/#{feedId}"

				message = @commonModel.get('notifyMessage').replace(/\[\[link\]\]/g, promotionLink)
				mailingTitle = "#{if isNew then 'Создание нового' else 'Обновление'} предложения \"#{ objectTitle }\""
				PENDING = Iconto.REST.Delivery.STATUS_PENDING
				RUNNING = Iconto.REST.Delivery.STATUS_RUNNING
				delivery = new Iconto.REST.Delivery
					company_id: companyId
					title: mailingTitle
					message: message
					status: PENDING

				delivery.save()
				.then =>
					delivery.save status: RUNNING # confirming
				.then =>
					alertify.success 'Рассылка успешно создана.'
				.dispatch(@)
				.catch (err) =>
					alertify.error 'Произошла ошибка при создании рассылки.'

			feedIdReceiver = (err,feedId) =>
				if err then return console.error err
				if feedId
					handleFeedId feedId
				else
					setTimeout =>
						getFeedItem feedIdReceiver
					, 500

			getFeedItem feedIdReceiver

		onFormSubmit: =>
			unless @model.get('worktime_from') then @model.set('worktime_from',@model.defaults.worktime_from)
			unless @model.get('worktime_to') then @model.set('worktime_to',@model.defaults.worktime_to)

			return false if @state.get('isSaving')

			@state.set
				isSaving: true

			isNew = @model.isNew()
			if isNew
				query = @model.toJSON()
			else
				query = (new @ModelClass(@buffer.toJSON())).set(@model.toJSON()).changed

				if _.isEmpty query
					@state.set 'isSaving', false
					return false

			@model.save query
			.then =>
				message = if isNew
					"#{@commonModel.get('entityName')} успешно создан."
				else
					'Изменения успешно сохранены.'

				alertify.success message
				@notifyUsers isNew

				route = @commonModel.get('successSavedRoute')
				Iconto.office.router.navigate route, trigger: true

				@state.set isSaving: false

			.dispatch(@)
			.catch (error) =>
				console.error error
				@state.set isSaving: false
				error.msg = switch error.status
					when 103135
						"#{@commonModel.get('entityName')} не найден"
					when 103143
						NO_REAL_CONTRACT_MESSAGE
					else
						error.msg
				Iconto.shared.views.modals.ErrorAlert.show error