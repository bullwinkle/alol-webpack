@Iconto.module 'feedback', (Feedback) ->
	class Feedback.Controller extends Marionette.Controller

		#/feedback/:addressSpotId(/)
		feedback: (addressSpotId) ->
			viewParams =
				addressSpotId: addressSpotId

			userPromise = new Iconto.REST.User(id: 'current')
			companyPromise = new Iconto.REST.Company(id: window.ICONTO_APPLICATION_DOMAIN_SETTINGS.company_id)

			companyPromise.fetch()
			.then (company) =>
				viewParams.company = company
				userPromise.fetch()
			.then (user) =>
				viewParams.user = user
			.catch (error) =>
				console.log error
			.done =>
				feedbackView = new Iconto.feedback.views.FeedbackView viewParams
				Iconto.commands.execute 'workspace:show', feedbackView