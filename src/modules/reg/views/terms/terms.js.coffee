@Iconto.module 'reg.views', (Views) ->

	class Views.TermsView extends Marionette.LayoutView
		template: JST['reg/templates/terms/terms']
		className: 'terms-layout'

		behaviors:
			Epoxy: {}

		ui:
			tabs: '.terms-tab'
			tabTerms: '.terms'
			tabTariffs: '.tariffs'
			dataContent: '.data-content'
			termsLink: '.terms-link'
			tariffsLink: '.tariffs-link'
			title: '.tab-bar h1'
			topbarLeftButton: '.topbar-region .left-small'

		events:
			'click @ui.menuSpan': 'onMenuClick'
			'click @ui.topbarLeftButton': 'onTopbarLeftButtonClick'

		serializeData: =>
			state: @state.toJSON()

		initialize: =>
			@state = new Iconto.reg.models.StateViewModel @options
			@state.set
				topbarLeftButtonClass: ''
				topbarLeftButtonSpanClass: 'ic-chevron-left'

				topbarTitle: 'Правила и тарифы'
#				topbarRightButtonSpanClass: 'ic-circle-checked'

				# name: ''
				# login: Iconto.shared.helpers.phone.format7(@model.get 'login')
				# acceptUntrusted: @options.user.settings.notifications.accept_untrusted

			@state.on 'change', @update


		onRender: =>
			@state.set 'isLoading', false
			@update()

		update: =>
			@ui.tabs.removeClass('active')
			if @state.get('subpage') isnt 'wrt'
				@ui.termsLink.attr 'href', "/#{@state.get('subpage')}/terms"
				@ui.tariffsLink.attr 'href', "/#{@state.get('subpage')}/tariffs"

			switch @state.get('subpage')
				when 'wallet'
					@ui.menuSpan.removeClass('ic-chevron-left')
					@ui.menuIcon.addClass('menu-icon hide-on-web-view')
					@ui.title.text 'Правила и тарифы'
					switch @state.get('page')
						when 'terms'
							@ui.tabTerms.addClass('active')
							@ui.dataContent.html JST['office/templates/terms/wallet-terms']()
						when 'tariffs'
							@ui.tabTariffs.addClass('active')
							@ui.dataContent.html JST['office/templates/terms/wallet-tariffs']()
				when 'office'
					@ui.menuIcon.removeClass('menu-icon hide-on-web-view')
					@ui.menuSpan.addClass('ic-chevron-left')
					@ui.title.text 'Правила и тарифы'
					switch @state.get('page')
						when 'terms'
							@ui.tabTerms.addClass('active')
							@ui.dataContent.html JST['office/templates/terms/office-terms']()
						when 'tariffs'
							@ui.tabTariffs.addClass('active')
							@ui.dataContent.html JST['office/templates/terms/office-tariffs']()
				when 'reg'
					@ui.title.text 'Правила и тарифы'
					switch @state.get('page')
						when 'terms'
							@ui.tabTerms.addClass('active')
							@ui.dataContent.html JST['reg/templates/terms/office-terms']()
						when 'tariffs'
							@ui.tabTariffs.addClass('active')
							@ui.dataContent.html JST['reg/templates/terms/office-tariffs']()
				when 'wrt'
					@ui.menuIcon.removeClass('menu-icon hide-on-web-view')
					@ui.menuSpan.addClass('ic-chevron-left')
					@ui.title.text 'Правила'
					switch @state.get('page')
						when 'terms'
							@ui.tabTerms.addClass('active').text('Условия использования АЛОЛЬ')
							@ui.tabTerms.addClass('hide')
							@ui.tabTariffs.addClass('hide')
							@ui.dataContent.html JST['office/templates/terms/wrt-terms']()

		onMenuClick: =>
			if @state.get('subpage') is 'office'
				if window.history and window.history.length >= 3
					Iconto.office.router.navigateBack()
				else
					Iconto.office.router.navigate '/office', trigger: true
			if @state.get('subpage') is 'wrt'
				if window.history and window.history.length >= 3
					Iconto.office.router.navigateBack()
				else
					Iconto.office.router.navigate '/', trigger: true

		onTopbarLeftButtonClick: =>
			Iconto.reg.router.navigate "/reg", trigger: true