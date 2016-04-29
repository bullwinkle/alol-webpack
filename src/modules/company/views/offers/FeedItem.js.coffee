@Iconto.module 'company.views.offers', (Offers) ->
	class Offers.FeedItemView extends Marionette.LayoutView
		tagName: 'li'
		
		className: 'feed-item-wrapper before-show'
		
		behaviors:
			Epoxy: {}

		regions:
			imagesRegion: '.images-container'

		ui:
			'el': '.content'
			'imagesContainer': '.images-container'
			'buttonFavourite': '.favourite'
			'buttonLike': '.button-with-icon.like'
			'companyName': '.company-name .link'
			'actionList': '.drop-down, .drop-down *'
			'shareVkIcon': '.share.vk'
			'shareFbIcon': '.share.fb'
			'shareTwIcon': '.share.tw'
			'cashbacksContainer': '.cashbacks-list'

		events:
			'click @ui.el': 'onElClick'
			'click @ui.imagesContainer': 'onImagesContainerClick'
			'click @ui.buttonFavourite': 'onButtonFavouriteClick'
			'click @ui.buttonLike': 'onButtonLikeClick'
			'click @ui.shareVkIcon': 'onIconShareVkClick'
			'click @ui.shareFbIcon': 'onIconShareFbClick'
			'click @ui.shareTwIcon': 'onIconShareTwClick'
			'click @ui.actionList': (e) -> e.preventDefault()

		getTemplate: (model=@options.model) ->
			switch model.get 'object_type'
				when Iconto.REST.PromoFeed.OBJECT_TYPE_PROMOTION, Iconto.REST.PromoFeed.OBJECT_TYPE_CASHBACK
					JST['company/templates/offers/feed-item']
				when Iconto.REST.PromoFeed.OBJECT_TYPE_CASHBACK_GROUP
					JST['company/templates/offers/feed-cashback-group']
				else
					JST['company/templates/offers/feed-item']

		initialize: ->
			@state = new Backbone.Model
				isHideButtonShown: false
				isCashbacksPreviewLoading: false
				cashbacksPreviews: []
				allCashbacksHref: '/#'

			@_localInitialize()

		_localInitialize: => # for owerriding
#			console.warn 'company feed item', window.location.origin+@generateDetailsHref()

		onRender: =>
			objectData = @model.get('object_data')
			imagesList = objectData.images or []

			switch @model.get 'object_type'
				when Iconto.REST.PromoFeed.OBJECT_TYPE_PROMOTION, Iconto.REST.PromoFeed.OBJECT_TYPE_CASHBACK
					@imagesRegion.show new Iconto.shared.views.ContentSlider images: imagesList
				when Iconto.REST.PromoFeed.OBJECT_TYPE_CASHBACK_GROUP
					defer = @loadCashBacksPreview.bind @
					setTimeout defer, 80 # need to wait some time to give browser ability to send request for next feed pack

			@state.set detailsHref: @generateDetailsHref()

#		onShow: =>
#			limit = 20
#			deferTime = (@_index%limit)*100
#
#			setTimeout @$el.removeClass.bind( @$el, 'before-show'), deferTime

		onBeforeDestroy: =>
			imagesList = @model.get('object_data').images or []
			if imagesList.length is 1
				@$('.company-info-container,.images-container').off 'click'
			else
				@$('.company-info-container').off 'click'

		onImagesContainerClick: (e) =>
			imagesList = @model.get('object_data').images or []
			if imagesList.length > 1
				e.preventDefault()
				e.stopPropagation()

		onButtonFavouriteClick: (e) =>
			e.stopPropagation()
			Iconto.api.auth()
			.then =>
				@model.set 'is_favourite', not @model.get 'is_favourite'
				@model.save( 'is_favourite': @model.get('is_favourite') )
				.catch ( error ) ->
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()
			.catch =>
				Iconto.shared.views.modals.PromptAuth.show
					preset: 'soft'
					successCallback: @onButtonFavouriteClick.bind @, e

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
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()
			.catch =>
				Iconto.shared.views.modals.PromptAuth.show
					preset: 'soft'
					successCallback: @onButtonLikeClick.bind @, e

		onIconShareVkClick: =>
			console.warn 'onIconShareVkClick', @
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

		onCashbackPreviewClick: (e) =>
			$this = $(e.currentTarget)
			cashbackId = $this.data('id')
			alertify.log "cashback #{cashbackId}"

		generateDetailsHref:  =>
			companyId = @model.get('company_id')
			addressId = @state.get('addressId')

			switch @model.get 'object_type'
				when Iconto.REST.PromoFeed.OBJECT_TYPE_PROMOTION
					"/wallet/company/#{companyId}/offers/promotion/#{ @model.get('id') }"

				when Iconto.REST.PromoFeed.OBJECT_TYPE_CASHBACK
					"/wallet/company/#{companyId}/offers/cashback/#{ @model.get('id') }"

				# feeds do not grouping on company page
				when Iconto.REST.PromoFeed.OBJECT_TYPE_CASHBACK_GROUP
					"/wallet/offers/cashbacks/#{companyId}"

		getAbsoluteDetailsHref: =>
			"#{window.location.origin}#{@state.get 'detailsHref'}"

		mapCashbacksWithFeeds: (cashback, feedItems) =>
			cashback.feedId = _.get (_.find feedItems, object_id: cashback.id), 'id', ''
			cashback

		loadCashBacksPreview: =>
			_feedItems = null
			@state.set
				isCashbacksPreviewLoading: true

			companyId = @model.get 'company_id'
			(new Iconto.REST.PromoFeedCollection()).fetch
				company_id: companyId
				object_type: 2
				limit: 2
				offset: 0
			.then (feedItems) =>
				_feedItems = feedItems
				cashbackIds = _.pluck feedItems, 'object_id'
				(new Iconto.REST.CashbackTemplateCollection()).fetchByIds cashbackIds
			.then (cashbacks) =>
				cashbackPreviews = _(cashbacks)
				.map @getPreviewConditions
				.map (cashback) =>
					@mapCashbacksWithFeeds cashback, _feedItems
				.value()
				@state.set cashbacksPreviews: cashbackPreviews
			.catch (err) =>
				console.error err
			.done =>
				@state.set 	isCashbacksPreviewLoading: false

		getPreviewConditions: (offer) =>
			conditions = []
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

			tmpConditions = [conditions[0],conditions[1]]
			offer.conditions = tmpConditions
			offer