@Iconto.module 'shared.views.userProfile.verification', (Verification) ->
	class PersonalInfo extends Backbone.Model
		defaults:
			first_name: ''
			last_name: ''
			middle_initial_name: ''
			date_of_birth: ''
			inn: ''
			snils: ''
			passport_series: ''
			passport_number: ''
			passport_computed: ''
			passport_issuer: ''
			passport_issued: ''
			passport_department: ''

		validation:
			first_name:
				required: true
				maxLength: 100
			last_name:
				required: true
				maxLength: 100
			middle_initial_name:
				required: false
				maxLength: 100
			date_of_birth:
				required: true
				maxUnixDate: moment().subtract(14, 'years').format('YYYY-MM-DD')
				msg: 'Вам должно быть больше 14 лет'
			inn:
				required: true
				length: 12
				inn: true
			snils:
				required: true
				length: 11
				snils: true
			passport_series:
				required: true
				length: 4
			passport_number:
				required: true
				length: 6
			passport_computed:
				required: true
				length: 10
			passport_issuer:
				required: true
				maxLength: 1000
			passport_issued:
				required: true
				maxUnixDate: moment().format('YYYY-MM-DD')
			passport_department:
				required: true
				length: 6

	_.extend PersonalInfo::, Backbone.Validation.mixin

	class Verification.VerificationView extends Marionette.ItemView
		className: 'verification-view mobile-layout'
		template: JST['shared/templates/user-profile/verification/verification']

		behaviors:
			Epoxy: {}
			Form:
				submit: '[name=send-button]'
				events:
					submit: 'form'
			Layout:
				template: JST['shared/templates/mobile-layout']

		ui:
		  sendButton: '[name=send-button]'

		validated: =>
			model: @model

		initialize: =>
			@model = new PersonalInfo()
			@user = new Iconto.REST.User(@options.user)

			@listenTo @model, 'change:passport_computed', @onPassportChange

			# [wallet|office]/profile
			@page = Backbone.history.fragment.split('/').slice(0, 2).join('/')

			@state = new Iconto.shared.models.BaseStateViewModel _.extend {}, @options,
				isLoading: false
				topbarTitle: 'Личные данные'
				breadcrumbs: [
					{title: 'Профиль', href: "/#{@page}"}
					{title: 'Личные данные', href: document.location.pathname}
				]

		onPassportChange: (model, value) =>
			passportSeries = ''
			passportNumber = ''

			if model.isValid('passport_computed')
				passportSeries = value.slice(0, 4)
				passportNumber = value.slice(4, 10)

			model.set
				passport_series: passportSeries
				passport_number: passportNumber

		onFormSubmit: (e) =>
			@ui.sendButton.disableButton()

			@user.save(personal_info: @model.toJSON())
			.then (response) =>
				@user.invalidate()
				Iconto.shared.router.navigate "/#{@page}/verification/status", trigger: true
			.dispatch(@)
			.catch (error) =>
				console.error error
				error.msg = switch(error.status)
					when 208111 then 'Неверный номер СНИЛС'
					else
						error.msg

				Iconto.shared.views.modals.ErrorAlert.show error
				console.log error
			.done =>
				@ui.sendButton.enableButton()