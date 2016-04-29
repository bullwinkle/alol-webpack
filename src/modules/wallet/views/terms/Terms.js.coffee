@Iconto.module 'wallet.views', (Views) ->
	class Views.TermsView extends Marionette.LayoutView
		template: JST['wallet/templates/terms/terms']
		className: 'terms-layout mobile-layout'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		ui:
			tabs: '.terms-tab'
			tabTerms: '.terms'
			tabTariffs: '.tariffs'
			dataContent: '.data-content'
			menuIcon: '.left-off-canvas-toggle'
			menuSpan: '.left-off-canvas-toggle span'
			termsLink: '.terms-link'
			tariffsLink: '.tariffs-link'
			title: '.tab-bar h1'

		events:
			'click @ui.menuSpan': 'onMenuClick'

		serializeData: =>
			state: @state.toJSON()

		initialize: =>
			@state = new Iconto.wallet.models.StateViewModel _.extend {}, @options,
				topbarTitle: 'Правила и тарифы'
				isLoading: false
				breadcrumbs: [
					{title: 'Профиль', href: '/wallet/profile'}
					{title: 'Правила и тарифы', href: '/wallet/terms'}
				]

			@listenTo @state, 'change', @update

		onRender: =>
			@update()

		update: =>
			console.log 'Updating terms and tariffs', @state.toJSON(), @ui

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
							@ui.dataContent.html JST['wallet/templates/terms/wallet-terms']()
						when 'tariffs'
							@ui.tabTariffs.addClass('active')
							@ui.dataContent.html JST['wallet/templates/terms/wallet-tariffs']()
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
				when 'wrt'
					@ui.menuIcon.removeClass('menu-icon hide-on-web-view')
					@ui.menuSpan.addClass('ic-chevron-left')
					@ui.title.text 'Правила'
					switch @state.get('page')
						when 'terms'
							@ui.tabTerms.addClass('active').text('Условия использования АЛОЛЬ')
							@ui.tabTerms.addClass('hide')
							@ui.tabTariffs.addClass('hide')
							@ui.dataContent.html JST['wallet/templates/terms/wrt-terms']()

		onMenuClick: =>
			if @state.get('subpage') is 'office'
				if window.history and window.history.length >= 3
					Iconto.wallet.router.navigateBack()
				else
					Iconto.wallet.router.navigate '/office', trigger: true
			if @state.get('subpage') is 'wrt'
				if window.history and window.history.length >= 3
					Iconto.wallet.router.navigateBack()
				else
					Iconto.wallet.router.navigate '/', trigger: true