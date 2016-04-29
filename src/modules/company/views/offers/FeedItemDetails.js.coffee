@Iconto.module 'company.views.offers', (Offers) ->
	class Offers.FeedItemDetailsView extends Marionette.LayoutView
		className: 'offers feed-item-details mobile-layout'
		template:  JST['company/templates/offers/feed-item-details']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		regions:
			imagesRegion: '.images-container'

		ui:
			'topbarLeftButton': '.topbar-region .left-small'
			'topbarRightButton': '.topbar-region .right-small'
			'topbarRightButtonSpan': '.topbar-region .right-small span'
			'addressesList': '.addresses'
			'buttonFavourite': 'button.favourite'
			'buttonLike': 'button.like'
			'companyName' : '.company-name'
			'companyIcon' : '.company-icon'
			'buttonWriteMessage': '.write-message'
			'addressItem':'.address-item'
			'hideOffer':'.hide-offer'
			'shareVkIcon': '.share.vk'
			'shareFbIcon': '.share.fb'
			'shareTwIcon': '.share.tw'

		events:
			'click @ui.topbarLeftButton' : 'onTopbarLeftButtonClick'
			'click @ui.topbarRightButton' : 'onTopbarRightButtonClick'
			'click @ui.buttonFavourite': 'onButtonFavouriteClick'
			'click @ui.buttonLike': 'onButtonLikeClick'
			'click @ui.buttonWriteMessage': 'onWrightToCompanyButtonClick'
			'click @ui.companyName, @ui.companyIcon' : 'onCompanyNameClick'
			'click @ui.addressItem' : 'onAddressItemClick'
			'click @ui.hideOffer' : 'onHideOfferClick'
			'click @ui.shareVkIcon': 'onIconShareVkClick'
			'click @ui.shareFbIcon': 'onIconShareFbClick'
			'click @ui.shareTwIcon': 'onIconShareTwClick'

		bindingSources: ->
			company: @company
			companyCategory: @companyCategory
			feedItemDetails: @feedItemDetails
			addresses: @addresses

		initialize: ->
			@state = new Iconto.shared.models.BaseStateViewModel @options
			@state.set
				topbarLeftButtonClass: ""
				topbarLeftButtonSpanClass: "ic-chevron-left"
				topbarRightButtonSpanClass: "is-visible"
				isLoading: true
				defaultImage: false
				promoImageUrl: '#'
				images: []
				addresses: []
				conditions: []
				topbarTitle: switch @options.objectType
					when 'promotion'
						'Детали анонса'
					when 'cashback'
						'Детали CashBack'

			@model = new Iconto.REST.PromoFeed(id: @options.offerItemId-0)
			@feedItemDetails = switch @options.objectType
				when 'promotion'
					new Iconto.REST.Promotion(cashback: '')
				when 'cashback'
					new Iconto.REST.CashbackTemplate()
			@company = new Iconto.REST.Company()
			@companyCategory = new Iconto.REST.CompanyCategory()
			@addresses = new Iconto.REST.AddressCollection()
			@feedItemDetails.on 'change:images', (model, images, params) =>
				if _.isArray images
					imageUrl = images[0]
				else if _.isString images
					imageUrl = images
				@state.set 'promoImageUrl', imageUrl

			@_localInitialize()

		_localInitialize: =>
			entityText =  switch @state.get('objectType')
				when 'promotion'
					'анонса'
				when 'cashback'
					'шаблона CashBack'
				else 'предложения'

#			breadcrumbs = switch @options.from
#				when 'feed'
#					[
#						{title: "Предложения", href: "/wallet/offers/feed"}
#						{title: "Детальная страница #{entityText}", href: "#"}
#					]
#				when 'company'
#					[
#						{title: "Предложения компании", href: "/wallet/company/#{@options.companyId}/offers"}
#						{title: "Детальная страница #{entityText}", href: "#"}
#					]
#				else
#					[
#						{title: "Предложения", href: "/wallet/offers/feed"}
#						{title: "Детальная страница #{entityText}", href: "#"}
#					]
#			@state.set
#				breadcrumbs: bre

		getRouteToBack: =>
			companyId = @state.get('companyId')
			addressId = @state.get('addressId')
			favourites = _.get Iconto.shared.helpers.navigation.parseUri(), 'query.favourites'

			route = switch @state.get 'from' # parameter from controller
				when 'feed'
					_route = "/wallet/offers/"
					if favourites
						_route +=  'favourites'
					else
						_route +=  'feed'
					_route
				when 'feed-cashback-group'
					"/wallet/offers/cashbacks/#{companyId}"
				when 'company'
					_route = "/wallet/company/#{companyId}"
					_route += "/address/#{addressId}" if addressId
					_route += "/offers"
					_route

			route

		onRender: =>
			@$el.addClass @state.get 'objectType'
			@model.fetch()
			.then =>
				unless @model.get('object_id')
					objectName = switch @state.get('objectType')
						when 'promotion'
							'Анонс'
						when 'cashback'
							'CashBack'
						else 'Объект'
					throw message: "#{objectName} не найден"
				@feedItemDetails.set(id: @model.get 'object_id').fetch()
				.then (object) =>
					switch @state.get('objectType')
						when 'cashback'
							if object.bank_id
								(new Iconto.REST.Bank(id: object.bank_id)).fetch()
								.then (bank) =>
									object.bank = bank
									@getConditions object
								.catch (error) =>
									console.error error
								.done()
							else
								@getConditions(object)
						when 'promotion'
							@getConditions object

					Q.all([
						@company.set(id: object.company_id).fetch(),
						@addresses.fetchByIds( _.uniq object.address_ids )
					])
					.then ([company, addresses]) =>
						@state.set
							addresses: addresses
							company: company
							topbarRightLogoUrl: _.get company, 'image.url', ''
							topbarRightLogoIcon: ICONTO_COMPANY_CATEGORY[_.get(company, 'category_id', '')] || ''

						@companyCategory.set(id: company.category_id ).fetch()
			.then =>
				@imagesRegion.show new Iconto.shared.views.ContentSlider images: @feedItemDetails.get('images')
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
				route = @getRouteToBack()
				Iconto.wallet.router.navigate route, trigger: true
			.done =>
				@state.set 'isLoading', false

		onTopbarLeftButtonClick: =>
			route = @getRouteToBack()

			@destroy()
			defer = =>
#				backRoute = Iconto.shared.router.getHistory(-1)
#				if backRoute
#					Iconto.shared.router.navigate Iconto.shared.router.getHistory(-1)
#				else
#					Iconto.wallet.router.navigate route, trigger: !App.workspace.currentView.mainRegion.hasView()

				Iconto.wallet.router.navigate route, trigger: !App.workspace.currentView.mainRegion.hasView()
			setTimeout defer, 10

		onTopbarRightButtonClick: =>
			route = "/wallet/company/#{@state.get('companyId')}/info"
			Iconto.shared.router.navigate route, trigger: true

		onButtonFavouriteClick: =>
			Iconto.api.auth()
			.then =>

				@model.set 'is_favourite', not @model.get 'is_favourite'
				@model.save( 'is_favourite': @model.get('is_favourite') )
				.catch (error) =>
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()

			.catch =>
				Iconto.shared.views.modals.PromptAuth.show preset: 'soft'

		onButtonLikeClick: (e) =>
			e.stopPropagation()

			Iconto.api.auth()
			.then =>

				isLiked = !@model.get('is_liked')
				likesCount = if isLiked then @model.get('likes_count')+1 else @model.get('likes_count')-1
				@model.set
					is_liked: isLiked
					likes_count: likesCount
				@model.save( 'is_liked': @model.get('is_liked') )
				.catch ( error ) ->
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()

			.catch =>
				Iconto.shared.views.modals.PromptAuth.show preset: 'soft'

		onCompanyNameClick: =>
			route = "wallet/company/#{ @company.get('id') }"
			Iconto.shared.router.navigate route, trigger: true

		onAddressItemClick: (e) =>
			addreddId = $(e.currentTarget).data('address-id')
			route = "wallet/company/#{ @company.get('id') }/address/#{addreddId}?from=feed_details&feed=#{@model.get("id")}&company=#{@state.get('companyId')}"
			Iconto.shared.router.navigate route, trigger: true

		onHideOfferClick: =>
			Iconto.api.auth()
			.then =>
				@model.destroy()
				.then =>
					@onTopbarLeftButtonClick()
			.catch =>
				Iconto.shared.views.modals.PromptAuth.show preset: 'soft'

		onWrightToCompanyButtonClick: =>
			if Iconto.api.userId
				@openChat()
			else
				Iconto.shared.views.modals.PromptAuth.show preset: 'soft'

		openChat: =>
			return false if @onWriteButtonClickLock
			@onWriteButtonClickLock = true
			@ui.buttonWriteMessage.addClass 'is-loading'
			roomView = new Iconto.REST.RoomView()

			reasons = []
			userId = Iconto.api.userId
			companyId = @model.get('company_id')
			addresses = @state.get('addresses')
			reasons.push {type: Iconto.REST.Reason.TYPE_USER, user_id: userId}
			reasons.push {type: Iconto.REST.Reason.TYPE_COMPANY, company_id: companyId}

			roomView.save(reasons: reasons)
			.then (response) =>
#				route = if @state.get('addresses').length > 1
#					"/wallet/company/#{companyId}/chat-straightway"
#				else
#					"/wallet/messages/chat/#{response.id}"
				message = "\"#{@feedItemDetails.get('title')}\". Мне интересно!"
				route = "/wallet/messages/chat/#{response.id}?message=#{message}"

				Iconto.shared.router.navigate route, trigger: true

			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
				switch error.status
					when Iconto.shared.services.WebSocket.STATUS_SESSION_EXPIRED
						Iconto.shared.views.modals.PromptAuth.show preset:'sessionExpired'
					else
						Iconto.shared.views.modals.ErrorAlert.show error

			.done =>
				@onWriteButtonClickLock = false
				@ui.buttonWriteMessage.removeClass 'is-loading'

		onIconShareVkClick: =>
			link = "https://vk.com/share.php?url=#{@getAbsoluteDetailsHref()}"
			Iconto.shared.helpers.openNativePopup
				url:link

		onIconShareFbClick: =>
			link = "https://www.facebook.com/sharer/sharer.php?t=TITLE&u=#{@getAbsoluteDetailsHref()}"
			Iconto.shared.helpers.openNativePopup
				url:link

		onIconShareTwClick: =>
			link = "https://twitter.com/share?via=TWITTER_HANDLE&text=TEXT&url=#{@getAbsoluteDetailsHref()}"
			Iconto.shared.helpers.openNativePopup
				url:link

		getAbsoluteDetailsHref: =>
			"#{window.location.href}"

		getConditions: (offer) =>
			conditions = []

			# -------------- TEST VALUES --------------

			#	offer.work_time = [
			#		[[0, 86399]]
			#		[[0, 86399]]
			#		[[0, 86399]]
			#		[[0, 86399]]
			#		[[0, 86399]]
			#		[[0, 86399]]
			#		[[0, 86399]]
			#	]
			#	offer.worktimeFrom = "10:00"
			#	offer.worktimeTo = "22:00"
			#	offer.price = "1000"
			#	offer.period_from = 1426324056
			#	offer.period_to = 1421442000
			#	offer.at_birthday = false
			#	offer.birthday_before = "6"
			#	offer.birthday_after = "5"
			#	offer.birthday_ages = "25"
			#	offer.sex = 2
			#	offer.first_buy = true
			#	offer.company_payment_count = 100
			#	offer.company_payment_sum = 100


			# ---------------- period_from ----------------
			# ---------------- period_to ------------------
			if offer.period_from
				today = moment().format('DD.MM.YYYY')
				period_from_date = moment.unix(offer.period_from).format('DD.MM.YYYY')
				period_from_time = ''

				if period_from_date is today
					period_from_time = moment.unix(offer.period_from).format('HH:mm')
					if period_from_time is '00:00'
						period_from_time = ''

				workPeriodString = "Доступно с #{moment.unix(offer.period_from).format('DD.MM.YYYY')} #{ period_from_time }"
				if offer.period_to
					periodTo = moment.unix(offer.period_to).format('DD.MM.YYYY')
					workPeriodString += " до #{periodTo}"

				conditions.push workPeriodString

			# ---------------- work_time, worktimeFrom, worktimeTo ----------------
			if offer.work_time
				weekDays = ['понедельникам','вторникам','средам','четвергам','пятницам','субботам','воскресеньям']
				workingDays = []
				timeFrom = ''
				timeTo = ''

				replaceChar = Iconto.shared.helpers.string.replaceCharAtIndex

				for [fromTo],i in offer.work_time
					unless _.isEmpty fromTo
						workingDays.push " #{weekDays[ i ]}"
						if _.isEmpty timeFrom
							timeFrom = moment().startOf('day').add('seconds', fromTo[0]).format('HH:mm')
						if _.isEmpty timeTo
							timeTo = if fromTo[1] >= 86399 then '24:00' else moment().startOf('day').add('seconds', fromTo[1]).format('HH:mm')

				if workingDays.length is 7
					workTimeString = "Действует ежедневно с #{timeFrom} до #{timeTo}"
				else
					workingDaysString = workingDays.join(', ')
					workingDaysString = replaceChar workingDaysString, workingDaysString.lastIndexOf(','), ' и '
					workTimeString = "Действует с #{timeFrom} до #{timeTo} по #{workingDaysString}"
				conditions.push "#{workTimeString}"

			# ---------------- price ----------------
			if offer.price
				conditions.push "Вы можете купить данную скидку за #{offer.price} рублей"

			# ---------------- at_birthday ----------------
			if offer.at_birthday
				offer.birthday_before = null
				offer.birthday_after = null

				conditions.push "Только в день рождения"

			# ---------------- birthday_before, birthday_after ----------------
			if offer.birthday_before or offer.birthday_after
				daysBeforeWord = Iconto.shared.helpers.declension(offer.birthday_before, ['день','дня','дней'])
				daysAfterWord = Iconto.shared.helpers.declension(offer.birthday_after, ['день','дня','дней'])
				if offer.birthday_before and offer.birthday_after
					daysBeforeString = if offer.birthday_before
						"за #{offer.birthday_before} #{daysBeforeWord} до"
					else ''
					daysAfterString = if offer.birthday_after
						"и #{offer.birthday_after} #{daysAfterWord} после"
					else ''
					conditions.push "В день рождения, #{daysBeforeString} #{daysAfterString}"
				else
					daysBeforeString = if offer.birthday_before
						"и за #{offer.birthday_before} #{daysBeforeWord} до него"
					else ''
					daysAfterString = if offer.birthday_after
						"и #{offer.birthday_after} #{daysAfterWord} после него"
					else ''
					conditions.push "В день рождения #{daysBeforeString} #{daysAfterString}"

			# ---------------- birthday_ages ----------------
			if offer.birthday_ages
				conditions.push "Для всех, кому исполняется #{offer.birthday_ages} лет"

			#  ---------------- sex ----------------
			if offer.sex
				switch offer.sex
					when 1
						conditions.push "Предложение действует только для мужчин"
					when 2
						conditions.push "Предложение действует только для женщин"

			# ---------------- first_buy ----------------
			if offer.first_buy
				conditions.push "Только при первой покупке"

			# ---------------- company_payment_count ----------------
			if offer.company_payment_count
				conditions.push "Для всех, кто совершил более #{offer.company_payment_count} покупок"

			# ---------------- company_payment_sum ----------------
			if offer.company_payment_sum
				conditions.push "Для всех, кто совершил покупок более, чем на #{offer.company_payment_sum} рублей"

			if offer.bank
				conditions.push "Действует для банков \" #{offer.bank.name} \""


			@state.set 'conditions', conditions