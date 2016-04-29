@Iconto.module 'operator', (Operator) ->
	updateWorkspace = (params) ->
		Iconto.commands.execute 'workspace:update', Operator.views.Layout, params

	class Operator.Controller extends Marionette.Controller
		#/operator/
		index: =>
			updateWorkspace
				page: 'all'

		#operator/chat/:chatId
		chat: (chatId) =>
			updateWorkspace
				page: 'chat'
				chatId: chatId

		redirect: ->
			Iconto.shared.router.navigate 'operator', trigger: true