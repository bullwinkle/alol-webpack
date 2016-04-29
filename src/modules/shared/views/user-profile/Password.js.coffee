@Iconto.module 'shared.views.userProfile', (UserProfile) ->
	class PasswordModel extends Backbone.Model
		defaults:
			old_password: ''
			password: ''
			password_1: ''

		validation:
			old_password:
				required: true
				rangeLength: [1, 200]

			password: (value, attr, computedState) ->
				unless /^[a-zA-Z0-9]+$/.test value
					return 'Пароль может содержать цифры, латинские буквы и не должен содержать пробелов'

				unless /[a-zA-Z]/.test value
					return 'Пароль должен содержать минимум одну букву латинского алфавита'

				unless /\d/.test value
					return 'Пароль должен содержать минимум одну цифру'

				unless 7 <= value.length < 200
					return 'Длина пароля должна быть от 7 до 200 символов'

				return false

			password_1: (value) ->
				if @get('password') is value
					return `undefined`
				else
					return 'Пароли не совпадают'

	_.extend PasswordModel::, Backbone.Validation.mixin

	class UserProfile.PasswordView extends Marionette.ItemView
		className: 'password-view mobile-layout'
		template: JST['shared/templates/user-profile/password']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		ui:
			changePasswordButton: '[name=change-password]'

		events:
			'click @ui.changePasswordButton': 'onChangePasswordButtonClick'

		initialize: ->
			@model = new PasswordModel()

			@page = Backbone.history.fragment.split('/').slice(0, 2).join('/')

			@state = new Iconto.shared.models.BaseStateViewModel _.extend {}, @options,
				isLoading: false
				topbarTitle: 'Смена пароля'
				breadcrumbs: [
					{title: 'Профиль', href: "/#{@page}"}
					{title: 'Смена пароля', href: "/#{@page}/password"}
				]

			Backbone.Validation.bind @

		onChangePasswordButtonClick: =>
			return false unless @model.isValid(true)

			if @model.get('old_password') is @model.get('password')
				Iconto.shared.views.modals.Alert.show
					title: 'Ошибка'
					message: 'Новый пароль не должен совпадать с текущим.'
			else
				@ui.changePasswordButton.attr('disabled', 'disabled').addClass('is-loading')
				dfd = $.ajax
					url: 'password'
					type: 'PUT'
					data: JSON.stringify
						password: @model.get('password')
						old_password: @model.get('old_password')
				Q(dfd)
				.then (response) =>
					if response.status is 0
						Iconto.shared.views.modals.Alert.show
							title: 'Пароль изменен'
							message: 'Ваш пароль был успешно изменен.'
							onCancel: =>
								Iconto.shared.router.navigate @page, trigger: true
					else
						response.msg = switch (response.status)
							when 208111 then "Новый пароль должен содержать цифры и латинские буквы, не должен содержать пробелы."
							when 202118 then "Текущий пароль неверен."
							when 101102 then "Вы уже использовали этот пароль ранее. Пожалуйста, введите новый."
							else
								response.msg
						Iconto.shared.views.modals.ErrorAlert.show response
				.done =>
					@ui.changePasswordButton.removeAttr('disabled', 'disabled').removeClass('is-loading')