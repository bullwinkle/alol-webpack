@Iconto.module 'shared.models', (Models) ->

	class Models.BaseStateViewModel extends Backbone.Epoxy.Model
		defaults:
			isLoading: true
			isLoadingMore: false

			topbarHidden: false
			topbarTitle: ''
			topbarSubtitle: ''

			topbarLeftButtonClass: 'menu-icon left-off-canvas-toggle hide-on-web-view'
			topbarLeftButtonDisabled: false
			topbarLeftButtonSpanClass: ''
			topbarLeftButtonSpanText: ''

			topbarRightButtonClass: ''
			topbarRightButtonDisabled: false
			topbarRightButtonSpanClass: ''
			topbarRightButtonSpanText: ''

			topbarRightLogoUrl: ''
			topbarRightLogoIcon: ''

			breadcrumbs: [] #format: title: '', href: ''
			tabs: [] #format: title: '', href: '', [active: true|false]

			page: ''
			subpage: ''

		computeds:
			topbarLeftButtonVisible:
				deps: ['topbarLeftButtonSpanText', 'topbarLeftButtonClass', 'topbarLeftButtonSpanClass']
				get: (buttonText, buttonClass, spanClass) ->
					!!buttonText or !!buttonClass or !!spanClass

			topbarRightButtonVisible:
				deps: ['topbarRightButtonSpanText', 'topbarRightButtonClass', 'topbarRightButtonSpanClass', 'topbarRightLogoUrl', 'topbarRightLogoIcon']
				get: (buttonText, buttonClass, spanClass, topbarRightLogoUrl, topbarRightLogoIcon) ->
					!!buttonText or !!buttonClass or !!spanClass or topbarRightLogoUrl or topbarRightLogoIcon

			topbarLeftButtonResultClass:
				deps: ['topbarLeftButtonClass', 'topbarLeftButtonVisible']
				get: (buttonClass, topbarLeftButtonVisible) ->
					visibleClass = if topbarLeftButtonVisible then ' is-visible' else ''
					buttonClass = if buttonClass then " #{buttonClass}" else ''
					"left-small#{visibleClass}#{buttonClass}"

			topbarRightButtonResultClass:
				deps: ['topbarRightButtonClass', 'topbarRightButtonVisible']
				get: (buttonClass, topbarRightButtonVisible) ->
					visibleClass = if topbarRightButtonVisible then ' is-visible' else ''
					buttonClass = if buttonClass then " #{buttonClass}" else ''
					"right-small#{visibleClass}#{buttonClass}"