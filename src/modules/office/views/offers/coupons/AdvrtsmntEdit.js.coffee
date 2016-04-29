@Iconto.module 'office.views.offers', (Offers) ->

	class Offers.AdvertisementEditView extends Marionette.ItemView
		className: 'advertisement-edit-view mobile-layout'
		template: JST['office/templates/offers/coupons/advrtsmnt-edit']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']


		ui:
			topbarRightButton: '.topbar-region .right-small'
			topbarLeftButton: '.topbar-region .left-small'
			uploadButton: '[name=upload]'
			file: '#image'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'
			'click @ui.uploadButton': 'onUploadClick'

		modelEvents:
			'validated:valid': ->
				@ui.topbarRightButton.removeAttr 'disabled' unless @isSaving
			'validated:invalid': ->
				@ui.topbarRightButton.attr 'disabled', true

		initialize: =>
			@model = new Iconto.REST.Advertisement
				id: @options.advertisementId
				company_id: @options.companyId

			@state = new Iconto.office.models.StateViewModel @options
			@state.set
				topbarTitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal, leadingComma: true)}"
				topbarSubtitle: if @model.isNew() then 'Новый анонс' else '&nbsp;'
				topbarLeftButtonClass: ''
				topbarLeftButtonSpanClass: 'ic-chevron-left'
				topbarRightButtonSpanClass: 'ic-circle-checked'

				file: ''
				imageUrl: ''

				progressPercents: 0

		onRender: =>
			promise = Q.fcall =>
				if @model.isNew()
					true
				else
					@buffer = new Iconto.REST.Advertisement()
					@model.fetch({}, {validate: false})
					.then (model) =>
						@state.set
							topbarSubtitle: model.title
							imageUrl: if model.images.length > 0 then model.images[0].url else ''
						@buffer.set model

			promise
			.then =>
				@state.set
					isLoading: false
			.done()

			@ui.topbarRightButton.attr 'disabled', true
			Backbone.Validation.bind @

		onTopbarLeftButtonClick: =>
			Iconto.office.router.navigate "office/#{@state.get('companyId')}/offers/advertisements", trigger: true

		onTopbarRightButtonClick: =>
			@isSaving = true
			@ui.topbarRightButton.attr 'disabled', true
			isNew = @model.isNew()
			if isNew
				promise = @model.save()
			else
				query = @buffer.set(@model.toJSON()).changed
				promise = Q.fcall =>
					unless _.isEmpty query
						@model.save query
					else
						true
			promise
			.then =>
				if isNew
					Iconto.shared.views.modals.Alert.show
						message: 'Анонс успешно создан'
						onCancel: =>
							Iconto.office.router.navigate "office/#{@state.get('companyId')}/offers/advertisements", trigger: true
				else
					Iconto.shared.views.modals.Alert.show
						message: 'Изменения успешно сохранены'
					Iconto.office.router.navigate "office/#{@state.get('companyId')}/offers/advertisement/#{@model.get('id')}", trigger: false, replace: true
			.catch (error) =>
				console.error error
				@ui.topbarRightButton.removeAttr 'disabled'
				Iconto.shared.views.modals.Alert.show error
			.done =>
				@isSaving = false

		onUploadClick: =>
			files = @ui.file.prop('files')
			return false unless files and files.length > 0
			Q($.ajax
				url: 'file'
				type: 'OPTIONS'
			)
			.then (response) =>
				throw new ObjectError response unless response.status is 0

				Q($.ajax
					url: response.data.file_upload_url
					type: 'POST'
					xhr: =>
						xhr = $.ajaxSettings.xhr()
						if xhr.upload.addEventListener
							xhr.upload.addEventListener 'progress', (e) =>
								if e.lengthComputable
									@state.set
										progressPercents: Math.round(e.loaded / e.total * 100)
						xhr
					data: files[0]
					contentType: false
					processData: false
				)
			.then (fileResponse) =>
				throw new ObjectError fileResponse unless fileResponse.status is 0

				@state.set
					imageUrl: fileResponse.data.url
				@model.set 'images', ["#{fileResponse.data.id}"], validate: true

			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.Alert.show error

			.done =>
				@state.set
					file: ''
					progressPercents: 0