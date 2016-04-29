@Iconto.module 'office.views', (Views) ->

	class Views.TermsView extends Marionette.LayoutView
		template: JST['office/templates/terms/terms']
		className: 'terms-layout mobile-layout'

		behaviors:
			Epoxy: {}
			Layout:
				template: JST['shared/templates/mobile-layout']

		ui:
			tabs: '.terms-tab'
			tabTerms: '.terms'
			tabAgreement: '.agreement'
			dataContent: '.data-content'
			menuIcon: '.left-off-canvas-toggle'
			menuSpan: '.left-off-canvas-toggle span'
			termsLink: '.terms-link'
			agreementLink: '.agreement-link'
			title: '.tab-bar h1'

#		events:
#			'click @ui.menuSpan': 'onMenuClick'
#			'click .topbar-region .left-small': 'onTopbarLeftButtonClick'

		serializeData: =>
			state: @state.toJSON()

		initialize: =>
			@state = new Iconto.office.models.StateViewModel @options
			@state.set
				topbarTitle: 'Правила и соглашение'
				breadcrumbs: [
					{title: 'Профиль', href: '/office/profile'}
					{title: 'Правила и тарифы', href: '/office/terms'}
				]
#				topbarLeftButtonSpanClass: ''
#				topbarLeftButtonClass: 'menu-icon left-off-canvas-toggle'


			@state.on 'change', @update

			console.log 'init'

		onRender: =>
			console.log 'render'
			@state.set 'isLoading', false
			@update()

		update: =>
			console.log 'Updating terms and tariffs', @state.toJSON(), @ui

			@ui.tabs.removeClass('active')
			if @state.get('subpage') isnt 'wrt'
				@ui.termsLink.attr 'href', "/#{@state.get('subpage')}/terms"
				@ui.agreementLink.attr 'href', "/#{@state.get('subpage')}/agreement"

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
							@ui.tabAgreement.addClass('active')
							@ui.dataContent.html JST['office/templates/terms/wallet-tariffs']()
				when 'office'
					@ui.menuIcon.removeClass('menu-icon hide-on-web-view')
					@ui.menuSpan.addClass('ic-chevron-left')
					@ui.title.text 'Правила и тарифы'
					switch @state.get('page')
						when 'terms'
							@ui.tabTerms.addClass('active')
							@ui.dataContent.html JST['office/templates/terms/office-terms']()
						when 'agreement'
							@ui.tabAgreement.addClass('active')
							@ui.dataContent.html JST['office/templates/terms/office-agreement']()
				when 'wrt'
					@ui.menuIcon.removeClass('menu-icon hide-on-web-view')
					@ui.menuSpan.addClass('ic-chevron-left')
					@ui.title.text 'Правила'
					switch @state.get('page')
						when 'terms'
							@ui.tabTerms.addClass('active').text('Условия использования АЛОЛЬ')
							@ui.tabTerms.addClass('hide')
							@ui.tabAgreement.addClass('hide')
							@ui.dataContent.html JST['office/templates/terms/wrt-terms']()

#		onMenuClick: =>
#			if @state.get('subpage') is 'office'
#				if window.history and window.history.length >= 3
#					Iconto.office.router.navigateBack()
#				else
#					Iconto.office.router.navigate '/office', trigger: true
#			if @state.get('subpage') is 'wrt'
#				if window.history and window.history.length >= 3
#					Iconto.office.router.navigateBack()
#				else
#					Iconto.office.router.navigate '/', trigger: true
#
#		onTopbarLeftButtonClick: =>
#			url = Backbone.history.fragment.split('/')[0] + '/profile'
#			Iconto.shared.router.navigate url, trigger: true