@Iconto.module 'shared.views.userProfile', (UserProfile) ->
	class UserProfile.ProfileEditView extends Marionette.ItemView
		className: 'mobile-layout user-profile-edit-view'
		template: JST['shared/templates/user-profile/user-profile-edit']

		behaviors:
			Epoxy: {}
			Form:
				submit: '[name=save-button]'
				events:
					submit: 'form'
			Layout:
				template: JST['shared/templates/mobile-layout']

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
			sendConfirmationEmailButton: '.send-confirmation-email'

		events:
			'click @ui.exitButton': 'onExitButtonClick'

			'change @ui.userImageInput': 'onUserImageInputChange'
			'click @ui.deleteImageButton': 'onDeleteImageButtonClick'

			'click @ui.userImageUploadButton': 'onUploadButtonClick'
			'click @ui.sendConfirmationEmailButton': 'sendConfirmationEmail'

		initialize: =>
			@model = new Iconto.REST.User @options.user
			# duplicate image id
			@model.set image_id: @model.get('image').id
			@buffer = new Iconto.REST.User @model.toJSON()

			@listenTo @model, 'change:email', =>
				# set valid email on every email change
				@state.set isEmailValid: true

			@page = Backbone.history.fragment.split('/').slice(0, 2).join('/')

			@state = new Iconto.shared.models.BaseStateViewModel _.extend {}, @options,
				topbarTitle: 'Редактирование профиля'
				isLoading: false
				breadcrumbs: [
					{title: 'Профиль', href: "/#{@page}"}
					{title: 'Редактирование профиля', href: "/#{@page}/edit"}
				]

				isEmptyUser: false
				isEmailValid: true # shows server error if email is already taken

		onRender: =>
			@model.fetch()
			.then (user) =>
				# disable birthday if is set
				@ui.birthdayInput.prop('disabled', true) if user.birthday

				# disable sex if is set
				@ui.sexRadio.prop('disabled', true) if user.sex

				# set buffer
				@buffer.set user

				# check user anonymity
				@state.set isEmptyUser: _.isEmpty(user.first_name + user.last_name)
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

			# omit image and image_id fields
			fields = _.omit (new Iconto.REST.User(@buffer.toJSON())).set(@model.toJSON()).changed, 'image', 'image_id', 'updated_at'

			unless _.isEmpty(fields)
				unless _.isEmpty(fields.email)
					fields.is_email_confirmed = false
				@model.save(fields)
				.then =>
					Q.fcall =>
						unless _.isEmpty(fields.email)
							@sendConfirmationEmail()

					.then =>
						Iconto.shared.views.modals.Alert.show
							title: 'Сохранено'
							message: 'Данные успешно сохранены.'
							onCancel: =>
								Iconto.shared.router.navigate "/#{@page}", trigger: true
				.dispatch(@)
				.catch (error) =>
					console.error error
					# 205105, 101107 - email already taken
					statusIsEmailTaken = 101107
					@state.set isEmailValid: error.status isnt statusIsEmailTaken
					Iconto.shared.views.modals.ErrorAlert.show error unless error.status is statusIsEmailTaken

		sendConfirmationEmail: =>
			Iconto.api.auth()
			.then =>
				Iconto.api.post 'confirmation-email',
					success_url: "#{window.location.origin}/wallet/profile"
					error_url: "#{window.location.origin}/wallet/profile/edit"
			.then =>
				@ui.sendConfirmationEmailButton.replaceWith '<button class="grey text" style="cursor:default;">Письмо отправлено</button>'
			.catch =>
#				Iconto.shared.router.navigate '/auth', trigger: true
				Iconto.commands.execute 'modals:auth:show'


		onUploadButtonClick: =>
			# emulate input[type=file] click
			@ui.userImageInput.click()

		onUserImageInputChange: =>
			file = @ui.userImageInput.prop("files")[0]
			return unless file
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
					fileService.read(file)
					.then =>
						@model.save(image_id: response.id)
						.then =>
							@model.fetch(null, reload: true)
						.then =>
							@model.set
								image_id: response.id
								image: response

							@ui.userImageUploadButton.prop('disabled', false).removeClass('is-loading')

							@ui.userImage.attr 'src', Iconto.shared.helpers.image.resize(response.url)
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
				title: 'Удаление изображения'
				message: 'Вы уверены, что хотите удалить изображение?'
				onSubmit: =>
					@model.save(image_id: 0)
					.then =>
						@model.fetch(null, reload: true)
					.then =>
						@model.set image_id: 0
						@buffer.set @model.toJSON()
						url = @model.get('image').url
						@ui.userImage.attr 'src', url
						# Trigger handler of wallet/views/Layout
						Iconto.commands.execute 'user:image:change', url
					.catch (error) =>
						console.error error
						Iconto.shared.views.modals.ErrorAlert.show error
					.done()