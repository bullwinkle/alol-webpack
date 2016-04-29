query = Iconto.shared.helpers.navigation.getQueryParams()

window.OAUTH_CLIENT_ID = query.client_id or ''
window.OAUTH_RESPONSE_TYPE = query.response_type or ''
window.OAUTH_REDIRECT_URL = query.redirect_url or ''
window.OAUTH_SCOPE = (query.scope or '').split(',')
window.APP_KEY = query.app_key or ''