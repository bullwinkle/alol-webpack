@Iconto.module 'root.views.wrt', (Wrt) ->

	class Wrt.Signup extends Marionette.LayoutView
		template: JST['root/templates/wrt/signup']
		className: 'signup-layout'

		ui:
			login: 'input[name=login]'
			hintText: '.hint-text'

		events:
			'submit form': 'onFormSubmit'

		onRender: =>
			$('#workspace').addClass('wrt')

		onBeforeDestroy: =>
			$('#workspace').removeClass('wrt')

		onFormSubmit: (e) =>
			e.preventDefault()
			e.stopPropagation()

			@ui.hintText.removeClass('show')

			login = @ui.login.val().trim().replace(/[\(,\),\-, ,\+]+/g, '')
			login = '7' + login if login.length is 10

			(new Iconto.REST.User()).save(login: login)
			.then =>
				@ui.hintText.addClass('show').text('Пароль был выслан Вам по СМС')
			.catch (error) =>
				console.error error
				text = switch (error.status)
					when 201106 then 'Пользователь с таким номером уже зарегистрирован'
					else
						'Произошла ошибка, попробуйте зарегистрироваться позже'
				@ui.hintText.addClass('show').text(text)
			.done()