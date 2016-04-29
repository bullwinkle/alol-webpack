@Iconto.module 'oauth.views', (Oauth) ->
	class ConfirmViewModel extends Backbone.Model
		defaults:
			client_id: 0
			redirect_url: ''
			response_type: ''
			app_key: ''
			scope: []

	class Oauth.ConfirmView extends Marionette.ItemView
		className: 'confirm-view'
		template: JST['oauth/templates/confirm']

		ui:
			companyName: '.company-name'
			companyImage: '.company-info .image'
			permissions: '.permissions'
			acceptButton: '[name=accept]'

			userName: '.user-name a'
			userImage: '.user-image'

		events:
			'click @ui.acceptButton': 'onAcceptClick'
			'click [name=cancel]': 'onCancelClick'

		initialize: =>
			@model = new ConfirmViewModel
				client_id: window.OAUTH_CLIENT_ID
				redirect_url: window.OAUTH_REDIRECT_URL
				response_type: window.OAUTH_RESPONSE_TYPE
				scope: window.OAUTH_SCOPE
				app_key: window.APP_KEY

			@company = new Iconto.REST.Company()

		onRender: =>
			user = @options.user
			@ui.userName.text Iconto.shared.helpers.user.getName(user).trim()
			@ui.userImage.css 'background-image', "url(#{user.image.url})"

			if @model.get('app_key')
				# standard OAuth with app_key
				@getCompanyByAppKey @model.get('app_key')
			else
				# InSales, get app key
				Q($.get("https://insales.iconto.net/get-merchant?shop=#{@model.get('client_id')}"))
				.then (response) =>
					@model.set app_key: response.app_key
					@getCompanyByAppKey(response.app_key)
				.catch (error) =>
					console.error error
				.done()

			for scope in @model.get('scope')
				switch scope
					when 'profile'
						@ui.permissions.addClass('user-info')
					when 'transaction'
						@ui.permissions.addClass('user-transactions')
					when 'statistic'
						@ui.permissions.addClass('user-statistics')

		getCompanyByAppKey: (appKey) =>
			# get company by app key
			(new Iconto.REST.Company()).fetch(filter_app_key: appKey)
			.then (company) =>

				# set company name and image
				@ui.companyName.text(company.name)
				@ui.companyImage.css 'background-image', "url(#{Iconto.shared.helpers.image.resize(company.image.url)})"

				# get company settings for company domain
				(new Iconto.REST.CompanySettings(id: company.id)).fetch()
				.then (companySettings) =>
					apiUrl = window.ICONTO_API_URL
					server = if apiUrl.indexOf('dev') > -1 then 'dev.' else if apiUrl.indexOf('stage') > -1 then 'stage.' else ''
					@ui.companyName.attr('href', "//#{companySettings.domain}.#{server}#{companySettings.origin}")

		onAcceptClick: (e) =>
			console.log e
			@ui.acceptButton.attr('disabled', 'disabled')

#			url = "#{window.ICONTO_API_URL.replace('rest', 'oauth')}auth?sid=#{$.cookie window.ICONTO_API_SID}"
			url = "#{window.ICONTO_API_URL.replace('rest', 'oauth')}auth"
			data =
				app_key: @model.get('app_key')
				redirect_uri: @model.get('redirect_url')
				scope: @model.get('scope').join()

			Iconto.api.post(url, data)
			.then (response) =>
				url = response.data.redirect_uri.replace(/&amp;/g, '&')
				if url.match(/^https:/)
					Q($.get(url))
					.then =>
						window.INSALES_SUCCESS = true
						window.close()
					.catch (error) =>
						console.error error
						@ui.acceptButton.removeAttr('disabled')
					.done()
				else
					window.location.href = url

		onCancelClick: =>
			window.close()