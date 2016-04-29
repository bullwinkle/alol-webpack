@Iconto.module 'office.views.company', (Company) ->
	MAX_FILE_SIZE = 1 # mb

	class Company.ProfileView extends Marionette.ItemView
		template: JST['office/templates/company/profile/profile']
		className: 'office-profile-view mobile-layout'

		behaviors:
			Epoxy: {}
			Layout: {}

		ui:
			companyImage: '.image'
			deleteButton: '.delete'
			uploadButton: '.upload'
			uploadInput: 'input[type=file]'

			hiddenUsers: '.hidden.user'
			showMoreUsersButton: '.show-more.users'

			hiddenAddresses: '.hidden.address'
			showMoreAddressesButton: '.show-more.addresses'

		events:
			'click @ui.uploadButton': 'onUploadButtonClick'
			'click @ui.deleteButton': 'onDeleteButtonClick'
			'change @ui.uploadInput': 'onUploadInputChange'

			'click @ui.showMoreUsersButton': 'onShowMoreUserButtonClick'
			'click @ui.showMoreAddressesButton': 'onShowMoreAddressesButtonClick'

		serializeData: =>
			_.extend @model.toJSON(), state: @state.toJSON()

		initialize: =>
			@model = new Iconto.REST.Company _.extend @options.company, image_id: @options.company.image.id

			@state = new Iconto.office.models.StateViewModel _.extend {}, @options,
				topbarTitle: ''
				topbarSubtitle: ''
				isLoading: false

				category_name: ''
				legal_name: "#{Iconto.shared.helpers.legal.getLegal(@options.legal, leadingComma: false)}"
				site: do =>
					url = @model.get('site')
					url = "//#{url}" unless /^(http[s]?:\/\/|\/\/)/.test(url)
					Iconto.shared.helpers.navigation.parseUri(url)
				employees: []
				addresses: []

		onRender: =>
			(new Iconto.REST.CompanyCategory(id: @model.get('category_id'))).fetch()
			.then (category) =>
				@state.set category_name: category.name
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

			(new Iconto.REST.ContactCollection()).fetchAll(company_id: @options.company.id)
			.then (employees) =>
				# uniq users because of duplicate entries
				userIds = _.unique _.compact _.pluck employees, 'user_id'

				# request users
				(new Iconto.REST.UserCollection()).fetchByIds(userIds)
				.then (users) =>
					# set users as employees
					@state.set employees: users
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

			(new Iconto.REST.AddressCollection()).fetchAll(company_id: @options.company.id)
			.then (addresses) =>
				@state.set addresses: addresses
			.dispatch(@)
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.ErrorAlert.show error
			.done()

		onShowMoreUserButtonClick: =>
			# bind then `cause they are added via underscrore afrer render
			@bindUIElements()
			@ui.hiddenUsers.toggleClass('hide')
			if @ui.showMoreUsersButton.text() is 'Показать все'
				@ui.showMoreUsersButton.text('Скрыть')
			else
				@ui.showMoreUsersButton.text('Показать все')

		onShowMoreAddressesButtonClick: =>
			# bind then `cause they are added via underscrore afrer render
			@bindUIElements()
			@ui.hiddenAddresses.toggleClass('hide')
			if @ui.showMoreAddressesButton.text() is 'Показать все'
				@ui.showMoreAddressesButton.text('Скрыть')
			else
				@ui.showMoreAddressesButton.text('Показать все')

		onDeleteButtonClick: =>
			Iconto.shared.views.modals.Confirm.show
				title: 'Удаление логотипа компании'
				message: 'Вы уверены, что хотите удалить изображение компании?'
				onSubmit: =>
					(new Iconto.REST.CompanyCategory(id: @model.get('category_id'))).fetch()
					.then (category) =>
						@model.save(image_id: 0)
						.then =>
							@model.set image_id: 0
							@ui.companyImage.css 'background-image', "url(#{category.icon_url})"
							$("#company-image").attr 'src', category.icon_url
					.catch (error) =>
						console.error error
					.done()

		onUploadButtonClick: (e) =>
			@ui.uploadInput.click()

		onUploadInputChange: =>
			@uploadImage @ui.uploadInput.prop("files")[0]

		uploadImage: (file) =>
			fileService = Iconto.shared.services.file
			fileService.read(file)
			.then (e) =>
				# file size in MB
				fileSize = e.total / 1024 / 1024
				if fileSize > MAX_FILE_SIZE
					throw status: 400777

				fileService.upload(file)
				.then (@response) =>
					@model.save(image_id: @response.id)
					.then =>
						@model.invalidate()
						@model.set image_id: @response.id
						$("#company-image").attr 'src', e.target.result
						@ui.companyImage.css 'background-image', "url(#{e.target.result})"
			.dispatch(@)
			.catch (error) ->
				console.error error
				error.msg = switch (error.status)
					when 400777 then 'Размер файла не должен превышать 1 МБ.'
					else
						error.msg
				Iconto.shared.views.modals.ErrorAlert.show error
			.done =>
				@ui.uploadInput[0].value = ''