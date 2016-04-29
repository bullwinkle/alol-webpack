@Iconto.module 'office.views.offers', (Offers) ->
	class Offers.CouponView extends Marionette.ItemView
		className: 'coupon-view mobile-layout'
		template: JST['office/templates/offers/coupons/coupon']

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']


		ui:
			topbarRightButton: '.topbar-region .right-small'
			topbarLeftButton: '.topbar-region .left-small'

		events:
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'
			'click @ui.topbarRightButton': 'onTopbarRightButtonClick'

		initialize: =>
			@model = new Iconto.REST.Coupon
				id: @options.couponId
				company_id: @options.companyId

			@state = new Iconto.office.models.StateViewModel @options
			@state.set
				topbarLeftButtonClass: ''
				topbarLeftButtonSpanClass: 'ic-chevron-left'
				topbarRightButtonSpanClass: 'ic-cross-circle'

				imageUrl: ''

		onTopbarLeftButtonClick: =>
			Iconto.office.router.navigate "office/#{@state.get('companyId')}/offers/coupons", trigger: true

		onTopbarRightButtonClick: =>
			Iconto.shared.views.modals.Confirm.show
				title: "Подтвердите удаление"
				message: "Вы действительно хотите удалить акцию?"
				onOk: =>
					@deleteCoupon()

		deleteCoupon: =>
			@ui.topbarRightButton.attr 'disabled', true
			@model.destroy()
			.then =>
				Iconto.office.router.navigate "office/#{@state.get('companyId')}/offers/coupons", trigger: true
			.catch (error) =>
				console.error error
				setTimeout =>
					Iconto.shared.views.modals.ErrorAlert.show error
				, 500
			.done =>
					@ui.topbarRightButton.removeAttr 'disabled'

		onRender: =>
			@model.fetch()
			.then (coupon) =>
				@state.set
					topbarTitle: "#{@options.company.name}#{Iconto.shared.helpers.legal.getLegal(@options.legal, leadingComma: true)}"
					topbarSubtitle: coupon.title

				if coupon.images.length > 0
					@state.set 'imageUrl', coupon.images[0].url
			.catch (error) =>
				console.error error
				Iconto.shared.views.modals.Alert.show error
			.done =>
				@state.set 'isLoading', false
