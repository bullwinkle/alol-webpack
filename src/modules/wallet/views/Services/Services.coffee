@Iconto.module 'wallet.views', (Views) ->

	companyIds = Iconto.REST.Company.MAIN_COMPANY_IDS

	class Views.ServicesLayout extends Marionette.LayoutView
		template: JST['wallet/templates/services/layout']
		className: "services-layout mobile-layout"
		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		ui:
			'taxi': '.menu-items .taxi'
			'restaurantBooking': '.menu-items .restaurant-booking'
			'beautySalon': '.menu-items .beauty-salon'
			'flowersDelivery': '.menu-items .flowers-delivery'
			'supermarket': '.menu-items .supermarket'
			'foodDelivery': '.menu-items .food-delivery'

#		events:
#			'click @ui.taxi': 'onTaxiClick'
#			'click @ui.restaurantBooking': 'onRestaurantBookingClick'
#			'click @ui.beautySalon': 'onBeautySalonClick'
#			'click @ui.flowersDelivery': 'onFlowersDeliveryClick'
#			'click @ui.supermarket': 'onSupermarketClick'
#			'click @ui.foodDelivery': 'onFoodDeliveryClick'

		initialize: ->
			@state = new Iconto.wallet.models.StateViewModel _.extend {}, @options,
				isLoading: true
				topbarTitle: 'Чем вам помочь?'
#				breadcrumbs: [
#					{title: 'Профиль', href: '/wallet/profile'}
#					{title: 'АЛОЛЬ', href: '/wallet/about'}
#				]

		onRender: =>
			apiUrl = window.ICONTO_API_URL
			@env = if apiUrl.indexOf('dev') >= 0 then 'dev' else if apiUrl.indexOf('stage') >= 0 then 'stage' else 'prod'

			@ui.taxi.attr 'href', @getTaxiLink()
			@ui.restaurantBooking.attr 'href', @getRestaurantBookingLink()
			@ui.beautySalon.attr 'href', @getBeautySalonLink()
			@ui.flowersDelivery.attr 'href', @getFlowersDeliveryLink()
			@ui.supermarket.attr 'href', @getSupermarketLink()
			@ui.foodDelivery.attr 'href', @getFoodDeliveryLink()

			@state.set 'isLoading', false

		getTaxiLink: =>
			companyId = Iconto.REST.Company.mapDomainToCompanyIds companyIds.taxi
			"#{Iconto.REST.Company.TAXI_FORM_PATH}?phone=#{@state.get('user').phone}&user_id=#{@state.get('user').id}&company_id=#{companyId}"

		getRestaurantBookingLink: =>
			companyId = Iconto.REST.Company.mapDomainToCompanyIds companyIds.restaurantBooking
			"/wallet/company/#{companyId}"

		getBeautySalonLink: =>
			companyId = Iconto.REST.Company.mapDomainToCompanyIds companyIds.beautySalon
			"/wallet/company/#{companyId}"

		getFlowersDeliveryLink: =>
			companyId = Iconto.REST.Company.mapDomainToCompanyIds companyIds.flowersDelivery
#			"/wallet/company/#{companyId}"
			"/wallet/messages/chat/new?query=цветы %23доставка"

		getSupermarketLink: =>
			companyId = Iconto.REST.Company.mapDomainToCompanyIds companyIds.supermarket
			"/wallet/company/#{companyId}"

		getFoodDeliveryLink: =>
			companyId = Iconto.REST.Company.mapDomainToCompanyIds companyIds.foodDelivery
#			"/wallet/company/#{companyId}"
			"/wallet/messages/chat/new?query=ресторан %23доставка"


		onTaxiClick: (e) =>
			$(e.currentTarget).addClass 'is-loading'
			companyId = Iconto.REST.Company.mapDomainToCompanyIds companyIds.taxi
			userId = @state.get('user').id

			@openChat userId, companyId
			.done =>
				$(e.currentTarget).removeClass 'is-loading'

		onRestaurantBookingClick: (e) =>
			$(e.currentTarget).addClass 'is-loading'
			companyId = Iconto.REST.Company.mapDomainToCompanyIds companyIds.restaurantBooking
			userId = @state.get('user').id

			@openChat userId,companyId
			.done =>
				$(e.currentTarget).removeClass 'is-loading'

		onBeautySalonClick: (e) =>
			$(e.currentTarget).addClass 'is-loading'
			companyId = Iconto.REST.Company.mapDomainToCompanyIds companyIds.beautySalon
			userId = @state.get('user').id

			@openChat userId,companyId
			.done =>
				$(e.currentTarget).removeClass 'is-loading'

		onFlowersDeliveryClick: (e) =>
			$(e.currentTarget).addClass 'is-loading'
			companyId = Iconto.REST.Company.mapDomainToCompanyIds companyIds.flowersDelivery
			userId = @state.get('user').id

			@openChat userId,companyId
			.done =>
				$(e.currentTarget).removeClass 'is-loading'

		onSupermarketClick: (e) =>
			$(e.currentTarget).addClass 'is-loading'
			companyId = Iconto.REST.Company.mapDomainToCompanyIds companyIds.supermarket
			userId = @state.get('user').id

			@openChat userId,companyId
			.done =>
				$(e.currentTarget).removeClass 'is-loading'

		onFoodDeliveryClick: (e) =>
			$(e.currentTarget).addClass 'is-loading'
			companyId = Iconto.REST.Company.mapDomainToCompanyIds companyIds.foodDelivery
			userId = @state.get('user').id

			@openChat userId,companyId
			.done =>
				$(e.currentTarget).removeClass 'is-loading'

		openChat: (userId=0, companyId=0) =>
			return false if @uiLock
			@uiLock = true
			roomView = new Iconto.REST.RoomView()

			reasons = []
			reasons.push {type: Iconto.REST.Reason.TYPE_USER, user_id: userId}
			reasons.push {type: Iconto.REST.Reason.TYPE_COMPANY, company_id: companyId}

			roomView.save(reasons: reasons)
			.then (response) =>
				@uiLock = false

				route = "/wallet/messages/chat/#{response.id}"
				Iconto.shared.router.navigate route, trigger: true

			.dispatch(@)
			.catch (error) =>
				console.error error
				@uiLock = false
				Iconto.shared.views.modals.ErrorAlert.show error


#from ios

#case RBServiceTypeTaxi: {
#suggestion.name = @"Вызов такси";
#suggestion.company_id = [self companyIdForCurrentNetworkEnvironment:@7324, @5451, @5451, nil];
#searchTerm = @"такси";
#break;
#}
#
#case RBServiceTypeGoodsDelivery: {
#suggestion.name = @"Организовать перевозку";
#suggestion.company_id = [self companyIdForCurrentNetworkEnvironment:@9, nil];
#break;
#}
#
#case RBServiceTypeRestaurantBooking: {
#suggestion.name = @"Бронь столиков в ресторанах";
#suggestion.company_id = [self companyIdForCurrentNetworkEnvironment:@7321, @5458, @5452, nil];
#//            searchTerm = @"ресторан кафе бар";
#break;
#}
#
#case RBServiceTypeFoodDelivery: {
#suggestion.name = @"Доставка еды из ресторанов";
#suggestion.company_id = [self companyIdForCurrentNetworkEnvironment:@9, nil];
#searchTerm = @"кафе бар ресторан #доставка";
#break;
#}
#
#case RBServiceTypeFlowersAndGifts: {
#suggestion.name = @"Доставить цветы и подарки";
#suggestion.company_id = [self companyIdForCurrentNetworkEnvironment:@10018, @5462, nil];
#searchTerm = @"цветы подарки #доставка";
#break;
#}
#
#case RBServiceTypeTransportTickes: {
#suggestion.name = @"Купить авиа и ж/д билеты";
#suggestion.company_id = [self companyIdForCurrentNetworkEnvironment:@9, nil];
#break;
#}
#
#case RBServiceTypeEventTickes: {
#suggestion.name = @"Купить билеты на мероприятия";
#suggestion.company_id = [self companyIdForCurrentNetworkEnvironment:@9, nil];
#break;
#}
#
#case RBServiceTypeToursAndHotels: {
#suggestion.name = @"Подобрать тур или отель";
#suggestion.company_id = [self companyIdForCurrentNetworkEnvironment:@9, nil];
#break;
#}
#
#case RBServiceTypeBeautySalons: {
#suggestion.name = @"Запись в салоны красоты";
#suggestion.company_id = [self companyIdForCurrentNetworkEnvironment:@7328, @5459, @5453, nil];
#//            searchTerm = @"салон красоты парикмахерская";
#break;
#}
#
#case RBServiceTypeCleaning: {
#suggestion.name = @"Организовать уборку";
#suggestion.company_id = [self companyIdForCurrentNetworkEnvironment:@9786, @5461, @5455, nil];
#break;
#}
#
#case RBServiceTypeLaundry: {
#suggestion.name = @"Химчистка и прачечная";
#suggestion.company_id = [self companyIdForCurrentNetworkEnvironment:@9, nil];
#break;
#}
#
#case RBServiceTypeSupermarket: {
#suggestion.name = @"Супермаркет на дом";
#suggestion.company_id = [self companyIdForCurrentNetworkEnvironment:@10578, @5463, @5457, nil];
#//            searchTerm = @"супермаркет #доставка";
#break;
#}
#
#case RBServiceTypeZoo: {
#suggestion.name = @"Зоосервисы";
#suggestion.company_id = [self companyIdForCurrentNetworkEnvironment:@9, nil];
#break;
#}
#
#case RBServiceTypeRealEstate: {
#suggestion.name = @"Недвижимость";
#suggestion.company_id = [self companyIdForCurrentNetworkEnvironment:@9, nil];
#break;
#}
#
#case RBServiceTypeGoodsForChildren: {
#suggestion.name = @"Детские товары";
#suggestion.company_id = [self companyIdForCurrentNetworkEnvironment:@9, nil];
#break;
#}
#
#case RBServiceTypeDoctor: {
#suggestion.name = @"Записаться к врачу";
#suggestion.company_id = [self companyIdForCurrentNetworkEnvironment:@10164, @5460, @5454, nil];
#break;
#}
#
#case RBServiceTypeFlowersDelivery: {
#suggestion.name = @"Доставить цветы 24/7";
#suggestion.company_id = [self companyIdForCurrentNetworkEnvironment:@10018, @5462, @5456, nil];
#break;
#}
#
#default:
#NSAssert(NO, @"There is no known suggestion for serviceType=%li", (long)type);
#return nil;
#}
#[01.07.15, 17:16:23] IOS Sergey Kokunov: + (NSNumber )companyIdForCurrentNetworkEnvironment:(NSNumber )prodCompanyId, ... {
#// arguments: prodCompanyId [,devCompanyId] [,stageCompanyId], nil
