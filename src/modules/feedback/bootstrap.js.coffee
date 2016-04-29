@Iconto.module 'feedback', (Feedback) ->

	Feedback.router = new Feedback.Router controller: new Feedback.Controller()

#	unless window.ICONTO_APPLICATION_DOMAIN_SETTINGS
#		Feedback.router.navigate 'notfound', trigger: true