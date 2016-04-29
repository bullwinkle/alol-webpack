@Iconto.module 'chat.views', (Views) ->
	class Views.SubmitAttachmentItemView extends Marionette.ItemView
		className: 'attachment'
		template: JST['chat/templates/submit-attachment-item']

		ui:
			image: 'img'
			loading: '.loading'

		events:
			'click': 'onClick'

		modelEvents:
			'change:success': 'onSuccessChange'

		onRender: =>
			file = @model.get('file')
			fileService = Iconto.shared.services.file

			fileService.read(file).then (e) =>
				@$el.css backgroundImage: "url(#{e.target.result})"
#				@ui.image.attr 'src', e.target.result
			.done()

			@uploading = fileService.upload(file)
			.then (response) =>
				unless response.url
					Iconto.shared.views.modals.Alert.show
						title: "Неверный формат"
						message: "Вы можете отправить только изображение. Допустимые форматы: .jpg, .png, .jpeg"
					@model.collection.remove @model
					@destroy()
					false

				@model.set
					file_id: response.id
					url: response.url
					success: true
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onClick: =>
			@trigger 'click', @model

		onSuccessChange: =>
			@ui.loading.hide()