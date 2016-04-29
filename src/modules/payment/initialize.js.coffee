query = Iconto.shared.helpers.navigation.getQueryParams()
sid = query['sid']

#if sid
#	if /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/.test document.location.hostname
#		$.cookie(window.ICONTO_API_SID, sid)
#	else
#		$.cookie(window.ICONTO_API_SID, sid, {domain: '.iconto.net'})

window.ICONTO_WEBVIEW = query['webview']