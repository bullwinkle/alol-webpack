@Iconto.module 'auth.views.userProfile', (UserProfile) ->
	class UserProfile.ProfileEditView extends Marionette.ItemView
		className: 'mobile-layout user-profile-edit-view auth-profile'
		template: JST['auth/templates/user-profile-edit']

		behaviors:
			Epoxy: {}
			Form:
				submit: '[name=save-button]'
				events:
					submit: 'form'
			Layout: {}

		validated: =>
			model: @model

		ui:
			userImage: '.user-image img'
			userImageInput: 'input[type=file]'
			userImageUploadButton: '[name=upload-button]'
			deleteImageButton: '.delete-image-button'
			saveButton: '[name=save-button]'
			exitButton: '[name=exit-button]'
			birthdayInput: 'input[name=birthday]'
			sexRadio: '[name=sex]'
			moreInfo: '.more-info'

		events:
			'click @ui.exitButton': 'onExitButtonClick'

			'change @ui.userImageInput': 'onUserImageInputChange'
			'click @ui.deleteImageButton': 'onDeleteImageButtonClick'
			'click @ui.userImageUploadButton': 'onUploadButtonClick'
			'click @ui.moreInfo': 'onMoreInfoClicked'

		initialize: =>
			@options.user.image_id = @options.user.image.id or @options.user.image_id or 0
			@model = new Iconto.REST.User @options.user
			@buffer = new Iconto.REST.User @options.user

			@listenTo @model, 'change:email', =>
				# set valid email on every email change
				@state.set isEmailValid: true

			@page = Backbone.history.fragment.split('/').slice(0, 2).join('/')

			@state = new Iconto.shared.models.BaseStateViewModel _.extend {}, @options,
				topbarTitle: 'Редактирование профиля'
				isLoading: false
				topbarLeftButtonClass: ''
				breadcrumbs: [
					{title: 'Заполнение профиля', href: "/#{@page}"}
				]

				isEmptyUser: false
				isEmailValid: true # shows server error if email is already taken

		onRender: =>
			Backbone.Validation.bind @ #TODO: find some time to figure out how to bind validation to multiple models

			@model.fetch()
			.then =>
				# disable birthday if is set
				@ui.birthdayInput.prop('disabled', true) if @model.get('birthday')

				# disable sex if is set
				@ui.sexRadio.prop('disabled', true) if @model.get('sex')

				# set buffer
				@buffer.set @model.toJSON()

				if _.isEmpty(@model.get('first_name'), @model.get('last_name'))
					@state.set
						isEmptyUser: true
#						topbarLeftButtonClass: 'text-button'
#						topbarLeftButtonSpanClass: ''
#						topbarLeftButtonSpanText: 'Выйти'
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

			@model.validate()

		onTopbarLeftButtonClick: =>
			unless @model.get('first_name') and @model.get('last_name')
				@onExitButtonClick()
			else
				Iconto.shared.router.navigate "/#{Backbone.history.fragment.split('/')[0]}/profile", trigger: true

		onExitButtonClick: =>
			Iconto.api.logout()
			.then =>
				Iconto.shared.router.navigate Iconto.defaultUnauthorisedRoute, trigger: true
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onFormSubmit: (e) =>
			# remove input focus on submit
			@$('input').blur()

			fields = (new Iconto.REST.User(@buffer.toJSON())).set(@model.toJSON()).changed

			unless _.isEmpty(fields)
				console.warn fields
				@model.save(fields)
				.then =>
					Q.fcall =>
						unless _.isEmpty(fields.email)
							Iconto.api.post 'confirmation-email',
								success_url: "#{window.location.origin}/wallet/profile"
								error_url: "#{window.location.origin}/confirmation-error"
					.then =>
						Iconto.shared.views.modals.Alert.show
							title: 'Сохранено'
							message: 'Данные успешно сохранены.'
							onCancel: =>
								Iconto.auth.router.complete()
				.dispatch(@)
				.catch (error) =>
					console.error error
					# 205105, 101107 - email already taken
					statusIsEmailTaken = 101107
					@state.set isEmailValid: error.status isnt statusIsEmailTaken
					Iconto.shared.views.modals.ErrorAlert.show error unless error.status is statusIsEmailTaken

		onUploadButtonClick: =>
			# emulate input[type=file] click
			@ui.userImageInput.click()

		onUserImageInputChange: =>
			file = @ui.userImageInput.prop("files")[0]

			# check valid types before uploading image
			validTypes = ['image/jpg', 'image/jpeg', 'image/png']
			unless _.contains validTypes, file.type
				Iconto.shared.views.modals.Alert.show
					title: 'Ошибка'
					message: 'Недопустимый тип файла. В качестве изображения пользователя может быть выбрано только изображение в формате JPG и PNG.'
			else
				@ui.userImageUploadButton.prop('disabled', true).addClass('is-loading')
				fileService = Iconto.shared.services.file
				fileService.upload(file)
				.then (response) =>
					console.log response
					fileService.read(file)
					.then =>
						@model.set(image_id: response.id)
						.save(image_id: response.id)
						.then =>
							@model.invalidate()
							@ui.userImage.attr 'src', Iconto.shared.helpers.image.resize(response.url)
							$("[name=profile] .avatar").attr 'src', Iconto.shared.helpers.image.resize(response.url)
							@ui.userImageUploadButton.prop('disabled', false).removeClass('is-loading')

							# Trigger handler of wallet/views/Layout
							Iconto.commands.execute 'user:image:change', response.url
				.catch (error) =>
					console.error error
					Iconto.shared.views.modals.ErrorAlert.show error
					@ui.userImageUploadButton.prop('disabled', false).removeClass('is-loading')
				.done =>
					@ui.userImageInput[0].value = ''

		onDeleteImageButtonClick: =>
			Iconto.shared.views.modals.Confirm.show
				title: 'Удаление изображения пользователя.'
				message: 'Вы уверены, что хотите удалить изображения пользователя?'
				onSubmit: =>
					@model.save(image_id: 0)
					.then (user) =>
						@model.fetch({},{reload: true})
						.then (user) =>
							@model.set(image: user.image)
							console.log user

#						@model.save(image_id: 0)
#						.then =>
#							@model.set image_id: 0
#							@ui.companyImage.attr 'src', category.icon_url
#							$("#company-image").attr 'src', category.icon_url
					.catch (error) =>
						console.error error
						Iconto.shared.views.modals.ErrorAlert.show error
					.done()

		onDeleteImageButtonClick: =>
			Iconto.shared.views.modals.Confirm.show
				title: 'Удаление логотипа компании'
				message: 'Вы уверены, что хотите удалить изображение компании?'
				onSubmit: =>
					@model.save(image_id: 0)
					.then =>
						@model.set(image_id: 0)
						.fetch({},{reload: true})
						.then (user) =>
							@ui.userImage.attr 'src', user.image.url
							$("[name=profile] .avatar").attr 'src', user.image.url
					.catch (error) =>
						console.error error
						Iconto.shared.views.modals.ErrorAlert.show error
					.done()

		onMoreInfoClicked: =>
			Iconto.shared.views.modals.Alert.show
				title: ''
				message: 'Компании могут предоставлять дополнительные привилегии, основываясь на ' +
					'Ваших демографических данных, поэтому мы ограничили возможность их изменения. Все должно быть честно!'
				