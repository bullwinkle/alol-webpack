#= require company/views/FAQ

@Iconto.module 'wallet.views.messages', (Messages) ->

	# FAQ tree-view recourcive item rendering
	class Messages.FAQItemCompositeView extends Iconto.company.views.FAQItemCompositeView


	# FAQ tree-view empty view
	class Messages.FAQEmptyView extends Iconto.company.views.FAQEmptyView


	# FAQ tree-view root list
	class Messages.FAQTreeView extends Iconto.company.views.FAQTreeView