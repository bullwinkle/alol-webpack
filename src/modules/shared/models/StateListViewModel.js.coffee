@Iconto.module 'shared.models', (Models) ->

	class Models.StateListViewModel extends Backbone.Epoxy.Model
		defaults:
			isLoading: true
			isLoadingMore: false

		computeds: {}