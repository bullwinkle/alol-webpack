Iconto.module 'shared.views.map', (Map) ->

	###
	TRIGGERS

	'map:ready': null
	'map:drag': 'Object'
	'map:dragend': 'Object'
	'map:idle': 'Object'

	###

	GEOCODE_BASE_URL = 'https://maps.googleapis.com/maps/api/geocode/json'

	class MapState extends Backbone.Model
		defaults:
			zoom: 10
			# Moscow
			lat: 55.75694
			lon: 37.62346

	class Map.BaseMapView extends Marionette.ItemView
		template: -> '<div></div>'
		className: 'map-view'

		behaviors:
			Epoxy: {}

		ui: {}

		events: {}

		initialize: (options={}) ->
			if options.latitude && options.longitude
				options.lat = options.latitude
				options.lon = options.longitude
				delete options.latitude
				delete options.longitude

			if options.coords?.latitude && options.coords?.longitude
				options.lat = options.coords.latitude
				options.lon = options.coords.longitude
				delete options.coords.latitude
				delete options.coords.longitude

			@mapState = new MapState options
			@on 'map:ready', @onMapReady

		onRender: =>
			if window.App?.getGoogleMap
				window.App.getGoogleMap().then @initGoogleMap

		onMapReady: =>
			@mapState.set 'ready', true

		initGoogleMap:  =>
			latlng = new google.maps.LatLng @mapState.get('lat'), @mapState.get('lon')
			@geocoder = new google.maps.Geocoder()

			# https://developers.google.com/maps/documentation/javascript/3.exp/reference?hl=ru#MapOptions
			mapEl = _.get @, 'ui.mapEl[0]', @el
			@gMap = new google.maps.Map mapEl,
				zoom: @mapState.get('zoom')
				center: latlng
				disableDefaultUI: true
				noClear: true

			google.maps.event.addListener @gMap, 'drag', =>
				@trigger 'map:drag', arguments

			google.maps.event.addListener @gMap, 'dragend', =>
				@trigger 'map:dragend', arguments

			google.maps.event.addListener @gMap, 'idle', =>
				@trigger 'map:idle', arguments

			@trigger 'map:ready'

		setCenter: (coords) =>
			unless @mapState.get 'ready'
				return @once 'map:ready', =>
					@setCenter.call @, coords

			promise = new Promise (resolve,reject) =>
				stateLat = @mapState.get('lat')
				stateLon = @mapState.get('lon')
				if coords and coords.lat and coords.lon
					# console.log '1'
					@mapState.set coords
					resolve coords
				else if stateLat and stateLon
					# console.log '2'
					resolve
						lat: stateLat
						lon: stateLon
				else
					# console.log '3'
					Iconto.shared.services.geo.getCurrentPosition()
					.then (geo) =>
						@mapState.set
							lat: geo.coords.latitude
							lon: geo.coords.longitude
						resolve
							lat: geo.coords.latitude
							lon: geo.coords.longitude
					.catch reject

			promise
			.then ({lat,lon}) =>
				latlng = new google.maps.LatLng lat, lon
				@gMap.setCenter latlng
				if _.get(@, 'currentPositionMarker') instanceof google.maps.Marker
					# if current positionMarker is exists - just return,
					# because setting center of map must not change your current position

					# @currentPositionMarker.setPosition latlng
					return 'ok'
				else
					@currentPositionMarker = new google.maps.Marker
						position: latlng
						map: @gMap
						title: 'Вы здесь'
			.catch (err) =>
				console.error err