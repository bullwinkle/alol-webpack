@Iconto.module 'wallet.views', (Views) ->
	class Views.Map extends Iconto.shared.views.map.BaseMapView
		template: JST['wallet/templates/map/map'] # '<div class="map-view"></div>'
		className: 'addresses-on-map-view mobile-layout'
		behaviors:
			Layout: {}
			Epoxy: {}

		ui:
			topBarLeftButton: ".topbar-region .left-small"
			mapEl: ".map-view"

		events:
			'click @ui.topBarLeftButton': "onTopBarLeftButtonClick"

		initialize: ->
			super

			@model = new Iconto.REST.Company(id: @options.companyId)

			@state = new Iconto.shared.models.BaseStateViewModel _.extend {}, @options,
				topbarTitle: 'Адреса'
				topbarLeftButtonClass: ''
				topbarLeftButtonSpanClass: 'ic-chevron-left'
				addresses: []

		onRender: ->
			super

			addressesPromise = (new Iconto.REST.AddressCollection()).fetchAll(company_id: @options.companyId)
			.dispatch(@)

			cardsPromise = (new Iconto.REST.CustomerDiscountCardCollection()).fetch(filters:
				company_id: @options.companyId)
			.dispatch(@)

			mapPromise = new Promise (resolve, reject) =>
				mapReady = @mapState.get 'ready'
				resolved = false
				success = =>
					resolved = true
					resolve true

				fail = =>
					resolved = false
					reject('map promise timeout')

				mapTimeOut = => if resolved then return else fail()
				if mapReady then return success() else @once 'map:ready', success
				setTimeout mapTimeOut, 3000

			Q.all [addressesPromise, mapPromise, cardsPromise]
			.spread (addresses, mapReady, cards) =>
				card = cards[0]

				# caststring to int
				addressIds = _.map card.address_ids, (id) ->
					+id

				_.each addresses, (address) ->
					address.discount_percent = 0
					address.discount_percent = card.percent if address.id in addressIds or card.accepted_everywhere

				@state.set addresses: addresses
				@drawMarkers()
			.catch (error) =>
				console.error error
			.finally =>
				@state.set
					isLoading: false
					isLoadingMore: false

		onTopBarLeftButtonClick: ->
			Iconto.shared.router.navigate '/wallet/cards', trigger: true

		drawMarkers: ->
			bounds = new google.maps.LatLngBounds()
			addresses = @state.get('addresses') || []
			_ addresses
			.map (address, i) =>
#				console.warn address.discount_percent
#				canvas = document.createElement('canvas')
#				canvas.width = 40
#				canvas.height = 40
#				context = canvas.getContext("2d")
#
#				centerX = canvas.width / 2
#				centerY = canvas.height / 2
#				radius = 20
#				context.beginPath();
#				context.arc(centerX, centerY, radius, 0, 2 * Math.PI, false);
#				context.fillStyle = 'white';
#				context.fill();
#				context.lineWidth = 1;
#				context.strokeStyle = '#000000';
#				context.stroke();
#
#				context.font = "11px Arial";
#				context.fillStyle = 'black';
#				context.fillText(address.discount_percent + '%', 0, 15)
#
#				image =
#					url: canvas.toDataURL(),
#					size: new google.maps.Size(30, 30)
#					origin: new google.maps.Point(0, 0)
#					anchor: new google.maps.Point(0, 0)
#				shape =
#					coords: [1, 1, 1, 104, 80, 104, 80 , 1]
#					type: 'poly'
#
				currentLatlng = new google.maps.LatLng address.lat, address.lng
				currentMarker = new google.maps.Marker
					position: currentLatlng
					map: @gMap
					label: "#{i + 1}"
					title: address.address

#					labelAnchor: new google.maps.Point(3, 30)
#					icon: image
#					shape: shape

				currentMarker.addListener 'click', () =>
					console.log 'clicked', arguments

					companyId = @state.get 'companyId'
					addressId = address.id
					route = "/wallet/company/#{companyId}/address/#{addressId}?from=company_addresses_map"
					Iconto.shared.router.navigate route, trigger: true

				bounds.extend currentLatlng
			.value()

			if addresses.length is 1
				@gMap.setZoom 14
				@gMap.setCenter
					lat: _.get addresses, '[0].lat', 59.95034453706
					lng: _.get addresses, '[0].lng', 30.34163665771
			else
				@gMap.fitBounds(bounds)


