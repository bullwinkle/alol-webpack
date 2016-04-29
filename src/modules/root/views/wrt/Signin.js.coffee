@Iconto.module 'root.views.wrt', (Wrt) ->
	class Wrt.Signin extends Marionette.LayoutView
		template: JST['root/templates/wrt/signin']
		className: 'signin-layout'

		ui:
			login: 'input[name=login]'
			password: 'input[name=password]'

		events:
			'submit form': 'onFormSubmit'

		onRender: =>
			$('#workspace').addClass('wrt')

		onBeforeDestroy: =>
			$('#workspace').removeClass('wrt')

		onFormSubmit: (e) =>
			e.preventDefault()
			e.stopPropagation()

			login = @ui.login.val().trim().replace(/[\(,\),\-, ,\+]+/g, '')
			login = '7' + login if login.length is 10
			password = @ui.password.val().trim()


			Iconto.api.login(login, password)
			.then =>
				Iconto.Root.router.navigate "/wallet/messages/chats", trigger: true
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()