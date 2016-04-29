@Iconto.module 'office.views.new', (New) ->
	class New.NewCompanyWizardLayout extends Iconto.shared.views.wizard.BaseWizardLayout
		className: 'new-company-wizard-layout'

		config: =>
			root: 'company'

			views:
				company:
					viewClass: New.CompanyView
					args: =>
						stepIcons: @stepIcons
						company: @company
					transitions:
						addresses: 'addresses'

				addresses:
					viewClass: New.AddressesView
					args: =>
						stepIcons: @stepIcons
						company: @company
						addressesData: @addressesData
					transitions:
						back: 'company'
						image: 'image'

				image:
					viewClass: New.ImageView
					args: =>
						stepIcons: @stepIcons
						company: @company
					transitions:
						back: 'addresses'
						legal: 'legal'

				legal:
					viewClass: New.LegalView
					args: =>
						stepIcons: @stepIcons
						legal: @legal
					transitions:
						back: 'image'
						submitRequest: =>
							@submitRequest()

		initialize: =>
			@model = new Backbone.Model()
			@company = new Iconto.REST.Company()
			@legal = new Iconto.REST.LegalEntity()
			@user = new Iconto.REST.User @options.user
			@contact = new Iconto.REST.Contact()

			@addressesData =
				addressIds: [] # deprecated
				addresses: []
				countryId: 0
				cityId: 0
				type: 0

			@stepIcons = ['document', 'marker', 'image', 'case']

		submitRequest: =>
			# show loader
			@wizardRegion.currentView.state.set isLoading: true

			Q.fcall =>
				# if legal has no id, create legal
				if @legal.get('id') is 0

					# validate once more time
					if @legal.isValid(true)

						# save legal
						@legal.save()
						.then (response) =>

							# return legal id
							return response.id
					else
						# strange case but still
						return 0
				else
					# return selected id
					return @legal.get('id')
			.then (legalId) =>
				# set legal to company, if no legal, company will be created without legal
				@company.set legal_id: legalId if legalId

				# get company changed fields only
				params = (new Iconto.REST.Company()).set(@company.toJSON()).changed
#				params. = Iconto.shared.helpers.navigation.parseUri

				# save company
				@company.save(params)
				.then (response) =>

					# return company id
					return response.company_id
			.then (companyId) =>
				# address creation promises
				addressPromises = []

				if @addressesData.addresses.length > 0
					# try creating addresses

					for address in @addressesData.addresses
						# prepare fields
						params =
							company_id: companyId
							address: address
							country_id: @addressesData.countryId
							city_id: @addressesData.cityId
							type: @addressesData.type

						# push promise
						addressPromises.push (new Iconto.REST.Address()).save(params)

				# process addresses creation
				Q.all(addressPromises)
				.dispatch(@)
				.catch (error) =>
					console.error 'Addresses creating error', error
				.done()

				# return company id
				companyId
			.then =>
				# invalidate user to update user roles, checking company right in Layout.js
				@user.invalidate()

				# navigate to companies
				Iconto.office.router.navigate "/office", trigger: true
			.dispatch(@)
			.catch (error) =>
				console.error error
				switch error.status
					when 208111
						error.msg = "Некорректный email"

				Iconto.shared.views.modals.ErrorAlert.show error

				# show view because of error
				@wizardRegion.currentView.state.set isLoading: false
			.done()