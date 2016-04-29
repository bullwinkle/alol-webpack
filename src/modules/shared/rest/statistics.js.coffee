
#AJAX_STATISTICS
window.ICONTO_AJAX_STATISTICS = {}
#load from localStorage
if Modernizr.localstorage
	statistics = window.localStorage['ICONTO_AJAX_STATISTICS']
	statistics = if statistics then JSON.parse(statistics) else {}
	window.ICONTO_AJAX_STATISTICS = statistics

$(document).ajaxSend (event, jqxhr, options) ->
	url = options.url
	if url.match window.ICONTO_API_URL
		url = url.replace window.ICONTO_API_URL, ''
		split = url.split('?')
		resource = split[0].replace(/\/+$/, '').replace(/\/+.*$/, '')


		statistic = window.ICONTO_AJAX_STATISTICS[resource]
		unless statistic
			statistic = window.ICONTO_AJAX_STATISTICS[resource] =
				count: 0
				maxTime: null
				minTime: null
				averageTime: null
				key: resource

		statistic.lastSendTime = new Date().getTime()
		jqxhr.ICONTO_AJAX_STATISTIC = statistic
	undefined

$(document).ajaxComplete (event, jqxhr, options) ->
	url = options.url
	if url.match window.ICONTO_API_URL
		statistic = jqxhr.ICONTO_AJAX_STATISTIC
		if statistic
			time = new Date().getTime() - statistic.lastSendTime
			statistic.maxTime ||= time
			statistic.minTime ||= time
			statistic.averageTime ||= time

			statistic.averageTime = (statistic.averageTime * statistic.count + time) / (statistic.count + 1)
			statistic.count++


			if time > statistic.maxTime
				statistic.maxTime = time
			else if time < statistic.minTime
				statistic.minTime = time
			delete jqxhr.ICONTO_AJAX_STATISTIC

			saveStatistics()
	undefined


#save to localstorage
saveStatistics = _.debounce ->
	if Modernizr.localstorage
		window.localStorage['ICONTO_AJAX_STATISTICS'] = JSON.stringify window.ICONTO_AJAX_STATISTICS
, 1000
