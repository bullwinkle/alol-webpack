#= require ./BaseMapView
Iconto.module 'shared.views.map', (Map) ->

	###
	TRIGGERS

	'map:drag': 'Object'
	'map:dragend': 'Object'
	'map:idle': 'Object'
	'map:addressDefined': 'Object'

	###

	class Map.AddressFinderMapView extends Iconto.shared.views.map.BaseMapView

		onRender: =>
			super()

			@ui.centerMarker = $('<div class="map-marker center"></div>').appendTo(@$el).eq(0)

			@on 'map:drag', =>
				if !@ui.centerMarker.hasClass 'is-raised'
					@ui.centerMarker.addClass 'is-raised'

			@on 'map:dragend', =>
				if @ui.centerMarker.hasClass 'is-raised'
					@ui.centerMarker.removeClass 'is-raised'

			@on 'map:idle', @defineAddress

		timeout1 = 0
		timeout2 = 0
		defineAddress: =>
			if @ui.centerMarker?.hasClass 'is-raised'
				@ui.centerMarker.removeClass 'is-raised'
			centerPoint = @gMap.getCenter()
			coords =
				lat: _.result centerPoint, 'lat'
				lon: _.result centerPoint, 'lng'
			@geocoder.geocode location: centerPoint,  (results, status) =>
				switch status
					# when "OK" # indicates that no errors occurred; the address was successfully parsed and at least one geocode was returned.
					# when "ZERO_RESULTS" # indicates that the geocode was successful but returned no results. This may occur if the geocoder was passed a non-existent address.
					when "OVER_QUERY_LIMIT" # indicates that you are over your quota, need to try one more some later, maybe one sec.
						clearTimeout timeout1
						return timeout1 = setTimeout @defineAddress, 1000
					# when "REQUEST_DENIED" # indicates that your request was denied.
					# when "INVALID_REQUEST" # generally indicates that the query (address, components or latlng) is missing.
					# when "UNKNOWN_ERROR" # indicates that the request could not be processed due to a server error. The request may succeed if you try again.

				address = _.get results, '[0].formatted_address', 'не определено'
				defer = =>
					@trigger 'map:addressDefined', {address, coords}
				clearTimeout timeout2
				timeout2 = setTimeout defer, 100