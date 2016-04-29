@Iconto.module 'wallet.views.money', (Money) ->
	class CardView extends Marionette.ItemView
		template: JST['wallet/templates/cards/card']
		className: 'card'

		attributes: ->
			'data-status': @getStatus()

		events:
			'click': 'onClick'
			'click [data-action]': 'onActionButtonClick'
			'click .disabled': -> false
			'click [name=connect-card-button]': 'onConnectCardClick'

		templateHelpers: =>
			getCompanyColor: =>
				color = _.get(@company, 'domain_settings.background_color')
				color = '' if color and color.toLowerCase() is '#ffffff'
				color
			getCompanyImage: =>
				url = _.get(@company, 'image.url')
				"style=\"background-image: url(#{url})\""
			getCompanyName: =>
				_.get(@company, 'name')
			getCurrency: =>
				result = ''
				balance = +@model.get('balance')
				if balance
					currency = @model.get('currency_name') || 'Бонусы'
					result = "#{currency}: #{balance}"
				result
			getDiscountPercent: =>
				discountPercent = +@model.get('percent')
				discountPercent = if discountPercent then discountPercent + '%' else '&nbsp;'
				discountPercent = @model.get('percent_prefix') + ' ' + discountPercent
				discountPercent
			getCardName: =>
				@model.get('title')
			getCompanyPhone: =>
				phone = _.get @company, 'phone', ''
				phone = "+#{phone}" if phone
				phone

		initialize: ->
			@company = _.findWhere @options.companies, id: @model.get('company_id')
			@company = @options.company unless @company

			@model.set
				rulesText: @company.rules_text
				rulesUrl: if @company.rules_url then Iconto.shared.helpers.navigation.parseUri(@company.rules_url).href else ''
				hasShop: @company.has_shop
				hasPhone: !!@company.phone
				hasCompanyRules: !!(@company.rules_text.trim() or @company.rules_url.trim())
				hasTaxi: +@company.category_id is 38 #[HARDCODED] taxi
				comingSoon: @company.alias == 'yandextaxi'

			@listenTo @model,
				'change:status', @onStatusChange

		onStatusChange: ->
			@$el.attr 'data-status': @getStatus()
			@trigger 'activate',
				model: @model.toJSON()
				company: @company

		getStatus: ->
			status = switch @model.get('status')
				when Iconto.REST.CustomerDiscountCard.STATUS_ACTIVE
					'active'
				when Iconto.REST.CustomerDiscountCard.STATUS_INACTIVE
					'inactive'
				when Iconto.REST.CustomerDiscountCard.STATUS_PENDING
					'pending'
			status

		onClick: ->
			@trigger 'click',
				model: @model.toJSON()
				company: @company

		# dispatch method handling click on card buttons
		onActionButtonClick: (e) ->
			e.stopPropagation()

			# check if exists
			action = $(e.currentTarget).data('action')
			return true unless action

			actions =
				catalog: 'openCatalog'
				promotions: 'openPromotions'
				messages: 'openChat'
				call: 'makeCall'
				rules: 'showRules'
				taxi: 'showTaxiForm'
				comingSoon: 'comingSoon'

			@[actions[action]](e)

		comingSoon: ->
			Iconto.shared.views.modals.LightBox.show
				html: """<div class="flexbox flex-v-center flex-h-center" style="
					position: absolute;
					top: 0;
					left: 0;
					width: 100%;
					height: 100%;">
					<img src="https://alol.io/static/images/original/1031518912186430.jpg">
				</div>"""

		openCatalog: ->
			return false unless @model.get('hasShop')
			switch @company.order_form_type
				when Iconto.REST.Company.SHOP_STATUS_DISABLED
					return Iconto.shared.views.modals.ErrorAlert.show
						title: 'Ошибка'
						message: 'Каталог компании отключен'

				when Iconto.REST.Company.SHOP_STATUS_AUTO, Iconto.REST.Company.SHOP_STATUS_ENABLED_INTERNAL
					route = "/wallet/company/#{@model.get('company_id')}/shop?from=#{location.pathname + location.search + location.hash}"
					Iconto.shared.router.navigate route, trigger: true

				when Iconto.REST.Company.SHOP_STATUS_ENABLED_EXTERNAL
					unless @company.order_form_url
						console.warn "В настройках компании указано 'показывать каталог по внешней ссылке', но сама внешняя ссылка не указана"
						return Iconto.shared.views.modals.ErrorAlert.show
							title: 'Ошибка'
							message: 'Каталог компании не доступен'
					externalShopUrl = Iconto.shared.helpers.navigation.parseUri(@company.order_form_url).href
					window.open externalShopUrl, '_blank'

				else
					route = "/wallet/company/#{@model.get('company_id')}/shop?from=#{location.pathname + location.search + location.hash}"
					Iconto.shared.router.navigate route, trigger: true

		openChat: ->
			Iconto.shared.helpers.messages.openChat
				companyId: @model.get('company_id')
				userId: @model.get('user_id')
			.then (response)=>
				route = "/wallet/messages/chat/#{response.id}?from=#{location.pathname + location.search + location.hash}"
				Iconto.shared.router.navigate route, trigger: true
			.dispatch(@)

		openPromotions: ->
			url = "/wallet/company/#{@model.get('company_id')}/offers?from=#{location.pathname + location.search + location.hash}"
			Iconto.shared.router.navigate url, trigger: true

		makeCall: ->
			return false unless @model.get('hasPhone')
			window.location = "tel:+#{@company.phone}"

		showRules: (e) =>
			return false unless @model.get 'hasCompanyRules'
			if @company.rules_url
				# 'href' and 'target' attrs added to link in the template
				return true
			else if @company.rules_text
				Iconto.shared.views.modals.LightBox.show
					html: JST['wallet/templates/cards/company-rules']
						heading: "Правила компании #{@company.name}"
						content: @company.rules_text

		onConnectCardClick: ->
			@model.save(status: Iconto.REST.CustomerDiscountCard.STATUS_ACTIVE)
			.then (response) =>
				# set status
				@model.set status: Iconto.REST.CustomerDiscountCard.STATUS_ACTIVE

				# this event is handled on details view
				@trigger 'activate',
					model: @model.toJSON()
					company: @company

				# rerender view
				@render()
			.catch (error) =>
				console.error error
				error.msg = 'Что-то пошло не так. Повторите еще раз позже'
				Iconto.shared.views.modals.ErrorAlert.show error

		showTaxiForm: =>
			route = "/wallet/services/taxi?company_id=#{@company.id}&from=#{location.pathname + location.search + location.hash}"
			Iconto.shared.router.navigate route, trigger: true

	class CardsListView extends Marionette.CollectionView
		childView: CardView
		childViewOptions: ->
			companies: @options.companies

		reorderOnSort: true

		onChildviewClick: (view, options) ->
			@children.each (child) ->
				child.$el.removeClass('active')
			view.$el.addClass('active')

		viewComparator: (model1, model2) ->
			if model1.get('status') > model2.get('status')
				return -1
			if model1.get('status') < model2.get('status')
				return 1
			if model1.get('status') is model2.get('status')
				if model1.get('rank') > model2.get('rank')
					return -1
				if model1.get('rank') < model2.get('rank')
					return 1
				if model1.get('rank') is model2.get('rank')
					return 0

		onRender: ->
			@insertPartnerSplitter()

		onBeforeReorder: ->
			@removePartnerSplitter()

		onReorder: ->
			@insertPartnerSplitter()

		removePartnerSplitter: ->
			@$('.partner-splitter').remove()

		insertPartnerSplitter: ->
			@children.each (view) ->
				unless view.model.get('status') is Iconto.REST.CustomerDiscountCard.STATUS_ACTIVE
					view.$el.before('<div class="partner-splitter">Рекомендуем</div>')
					false

	class Money.CardsView extends Marionette.LayoutView
		className: 'mobile-layout cards-view'
		template: JST['wallet/templates/cards/cards']

		behaviors:
			Epoxy: {}
			Layout: {}
			QueryParamsBinding:
				bindings: [
					model: 'state'
					fields: ['selectedCard']
				]

		regions:
			cardsRegion: '.cards'
			detailsRegion: '.details'

		#ui:
		#events:

		initialize: ->
			@model = new Iconto.REST.User(@options.user)

			@state = new Iconto.wallet.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Карты'
				isLoading: true
				hasCards: false
				selectedCard: null # card.model.id

			@listenTo @state, 'change:selectedCard', @onStateSelectedCardChange

		onRender: ->
			@cards = new Iconto.REST.CustomerDiscountCardCollection()
			@companies = new Iconto.REST.CompanyCollection()
			@masterCards = new Iconto.REST.MasterCardCollection()

			parsedUrl = Iconto.shared.helpers.navigation.parseUri()
			selectedCardId = +(_.get(parsedUrl, 'query.selectedCard', 0))

			# get user master cards
			@masterCards.fetch()
			.then (cards) =>
				unless cards.length
					Iconto.shared.router.navigate 'wallet/cards/mastercard', trigger: true
					return false
				else
					# get user customer discount cards
					@cards.fetch(user_id: @options.user.id)
			.then (cards) =>
				return unless @cards.length

				uPromise = (new Iconto.REST.CompanyCollection()).fetch(alias: Iconto.REST.Company.ALIAS_ULMART)
				rPromise = (new Iconto.REST.CompanyCollection()).fetch(alias: Iconto.REST.Company.ALIAS_RYADY)

				Promise.all([uPromise, rPromise])
			.spread (ulmart=[], ryady=[]) =>
				if ulmart.length or ryady.length
					ulmart = ulmart[0]
					uRank = 100
					ryady = ryady[0]
					rRank = 50

					@cards.each (card) ->
						rank = 0
						if card.get('company_id') is ulmart.id
							rank = uRank
						if card.get('company_id') is ryady.id
							rank = rRank
						card.set rank: rank

				# fetch companies by cards
				@companies.fetchByIds(_.compact(_.uniq(@cards.pluck('company_id'))))
			.then (companies) =>
				# active cards create view
				cardsListView = new CardsListView
					collection: @cards
					companies: companies

				# set childview click handler
				@listenTo cardsListView,
					'childview:click': @onCardClick
					'childview:activate': @onCardActivate

				# show region
				@cardsRegion.show cardsListView

				if @cards.length
					if !selectedCardId
						cardsListView.children.first().$el.click()
					else
						selectedCardView = cardsListView.children.find (view) ->
							view.model.get('id') is selectedCardId
						selectedCardView.$el.click()

			.then =>
				@state.set
					isLoading: false
					hasCards: @cards.length > 0
			.catch (error) =>
				console.error error
				@state.set
					isLoading: false
					hasCards: false

		onCardClick: (view, options) ->
			@state.set 'selectedCard', options.model.id
			@selectCard view, options

		selectCard: (view, options) ->
			model = options.model
			company = options.company

			cardView = new CardView
				model: new Iconto.REST.CustomerDiscountCard model
				company: company

			@listenTo cardView,
				'activate': @onCardActivate

			@detailsRegion.show cardView

		onCardActivate: (options) ->
			model = new Iconto.REST.CustomerDiscountCard(options.model)
			model = @cards.add model, {merge: true}
			@cardsRegion.currentView.reorder()
			view = @cardsRegion.currentView.children.findByModel(model)
			view.$el.attr 'data-status', view.getStatus()

		onStateSelectedCardChange: (cardId) =>
			# put some logic here, if needed