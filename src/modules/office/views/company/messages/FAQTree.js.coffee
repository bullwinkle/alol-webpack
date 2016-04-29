#= require company/views/FAQ

@Iconto.module 'office.views.company.settings', (Company) ->
	class Company.FAQItemCompositeView extends Iconto.company.views.FAQItemCompositeView
		template: JST['office/templates/company/FAQ/faq-item']
		className: 'faq-item button list-item menu-item l-pr-0'
		childView: Company.FAQItemCompositeView

		ui: _.extend {}, Iconto.company.views.FAQItemCompositeView::ui,
			'editButton': '.edit'

		events: _.extend {}, Iconto.company.views.FAQItemCompositeView::events,
			'click @ui.editButton':  'onEditButtonClick'

		onEditButtonClick: (e) =>
			e.stopPropagation()
			id = @model.get 'id'
			companyId = @model.get 'company_id'
			routeEntityName = switch @model.get 'type'
				when Iconto.REST.CompanyFAQ.TYPE_QUESTION then 'question'
				when Iconto.REST.CompanyFAQ.TYPE_CATEGORY then 'theme'
			route = "/office/#{companyId}/settings/messages/faq-#{routeEntityName}/#{id}"
			Iconto.shared.router.navigate route, trigger: true



	class Company.FAQEmptyView extends Iconto.company.views.FAQEmptyView
		template: -> 'Для этой компании нет FAQ'
		className: 'faq-item text-center f-lh-50'


	class Company.FAQTreeView extends Iconto.company.views.FAQTreeView
		template: JST['office/templates/company/FAQ/faq-list']
		className: 'faq-list-view scroll-parent l-p-r'
		childView: Company.FAQItemCompositeView
		emptyView: Company.FAQEmptyView
		initialize: ->
			super
			@listenTo Iconto.events,
				"faq:item:create": @onChildCreate
				"faq:item:update": @onChildUpdate
				"faq:item:delete": @onChildDelete
				"faq:category:create": @onChildCreate
				"faq:category:update": @onChildUpdate
				"faq:category:delete": @onChildDelete

		getQuery: =>
			companyId = @options.companyId
			filters: company_id: companyId
			show: 'all'

		calculateHeight: (isVisible) =>
			return new Promise (resolve, reject) => resolve ''

		onChildDelete: (modelObj) =>
			removedView = @findViewByModelId modelObj.id
			removedView.model.destroy()

		onChildUpdate: (modelObj={}) =>
			childView = @findViewByModelId modelObj.id

			return false unless childView instanceof Backbone.View

			# if entity parent_id was changed then move it to new parent collection and remove it from old
			if 	modelObj.parent_id isnt childView.model.get('parent_id')
				oldParent = @findViewByModelId(childView.model.get('parent_id')) || @
				newParent = @findViewByModelId(modelObj.parent_id) || @
				childView.model.set modelObj
				_.defer =>
					m = oldParent.collection.remove childView.model
					_.defer =>
						newParent.collection.add m

			# base update with rerender new data
			else
				childView.model.set modelObj
				childView.render()

		onChildCreate: (modelObj={}) =>
			modelObj.parent_id ||= 0
			unless modelObj.parent_id
				@collection.add modelObj
			else
				child = @findViewByModelId modelObj.parent_id
				if child
					child.collection.add modelObj

		findNode: (searchModelId, currentView) =>
			found = null
			if searchModelId == currentView.model.get 'id'
				currentView
			else
				i = 0
				while i < _.get currentView, 'children.length', 0
					currentChild = currentView.children.findByIndex(i)
					found = @findNode(searchModelId, currentChild)
					if found != false
						return found
					i += 1
				false

		findViewByModelId: (searchModelId) =>
			result = null
			@children.each (view,i) =>
				res = @findNode searchModelId, view
				if res then result = res
			result