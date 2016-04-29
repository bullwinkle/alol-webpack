@Iconto.module 'office', (Office) ->
	updateWorkspace = (params) ->
		Iconto.commands.execute 'workspace:update', Office.views.Layout, params

	class Office.Controller extends Marionette.Controller

		#/office
		index: ->
			(new Iconto.REST.CompanyCollection()).fetchIds(filters: ['my'])
			.then (companyIds) ->
				if companyIds.length is 1
					# redirect to company messages
					Iconto.office.router.navigate "office/#{companyIds[0]}/messages/chats", trigger: true
				else
					updateWorkspace page: 'index'
			.catch (error) ->
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		#/other
		pageNotFound: ->
			updateWorkspace
				page: 'pageNotFound'

		#about
		#/office/about
		about: =>
			updateWorkspace
				page: 'about'

		#/office/terms
		terms: =>
			updateWorkspace
				page: 'terms'
				subpage: 'office'

		#/office/agreement
		agreement: =>
			updateWorkspace
				page: 'agreement'
				subpage: 'office'

		#/office/new
		newCompany: ->
			updateWorkspace page: 'index', subpage: 'new-company'

		#/office/new/legal
		newLegal: ->
			updateWorkspace page: 'index', subpage: 'new-legal'

		#/office/profile
		profile: ->
			updateWorkspace
				page: 'user-profile'

		#/office/profile/blacklist
		profileBlacklist: ->
			updateWorkspace
				page: 'user-profile'
				subpage: 'blacklist'

		#/office/profile/mastercards
		profileMastercards: ->
			updateWorkspace
				page: 'user-profile'
				subpage: 'mastercards'

		#/office/profile/password
		profilePassword: ->
			updateWorkspace
				page: 'user-profile'
				subpage: 'password'

		profileEdit: ->
			updateWorkspace
				page: 'user-profile'
				subpage: 'edit'

		#/office/payment(/)
		#/office/payment(/)?order_id=:orderId
		payment: (orderId) =>
			orderId = Iconto.shared.helpers.navigation.getQueryParams()['order_id'] - 0 || 0;
			if orderId
				order = new Iconto.REST.Order id: orderId
				order.fetch()
				.then (order) =>
					Iconto.shared.loader.load('payment')
					.then =>
						updateWorkspace
							page: 'payment'
							orderId: orderId
							order: order
				.catch (error) =>
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
				.done()