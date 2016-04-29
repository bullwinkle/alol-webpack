class Iconto.REST.Task extends Iconto.REST.RESTModel
	urlRoot: 'task'

	@TYPE_UNKNOWN                           = 0
	@TYPE_GENERATE_BILL                     = 1
	@TYPE_IMPORT_COMPANY_CLIENTS_FROM_FILE  = 2
	@TYPE_GENERATE_ANALYTICS                = 4

	@STATUS_UNKNOWN     =  @TYPE_UNKNOWN_STATUS    = ''
	@STATUS_PENDING     =  @TYPE_PENDING_STATUS    = 'pending'
	@STATUS_PROCESSING  =  @TYPE_PROCESSING_STATUS = 'processing'
	@STATUS_COMPLETED   =  @TYPE_COMPLETED_STATUS  = 'completed'
	@STATUS_ERROR       =  @TYPE_ERROR_STATUS      = 'error'
	@STATUS_TIMEOUT     =  @TYPE_TIMEOUT_STATUS    = 'timeout'

	defaults:
		type: @TYPE_UNKNOWN
		status: @TYPE_PENDING_STATUS
		args: {}

	_waitRecursive: (times) => #NOT TESTED!
		@checkCounter = times if times
		unless @checkCounter is 0
			@fetch({}, reload: true)
			.then (task) =>
					unless @checkCounter is 0
						if task.status is Iconto.REST.Task.TYPE_PROCESSING_STATUS
							setTimeout =>
								unless @isDestroyed
									console.log task
									@checkCounter -= 1
									@wait() #recursive counting
							, 1000
					else
						@task.set 'status', Iconto.REST.Task.TYPE_ERROR_STATUS
			.done()

	stopPolling: =>
		@_pollLock = true

	startPolling: (times, options) =>
		@poll(times, options)

	#TODO: remove poll method completely
	poll: (times, options) => #TODO: rewrite using recursion + _.defer
		@_pollLock = false
		options ||= {}
		#set up counter if specified
		counter = times if times
		#set intervals
		taskCheckInterval = setInterval =>
			#if waiting process was interrupted
			if @_pollLock
				clearInterval(taskCheckInterval)
				return false

			if counter is 0

				#timeout
				clearInterval(taskCheckInterval)
				@set 'status', Iconto.REST.Task.STATUS_TIMEOUT

			else

				@fetch({}, reload: true)
				.then (task) =>
					if @_pollLock
						clearInterval(taskCheckInterval)
						return false
					options.success?(task)
					counter--
					#check if task is still processing
					unless task.status is Iconto.REST.Task.STATUS_PROCESSING
						#clear @taskCheckInterval
						clearInterval(taskCheckInterval)
				.catch (error) =>
					console.error error
					#assume options.error can return false - stop polling, otherwise (true) - continue
					if options.error
						unless options.error(error)
							#error returned false - stop polling
							clearInterval(taskCheckInterval)
							@stopPolling()
						#otherwise - continue
					else
						#stop
						clearInterval(taskCheckInterval)
						@stopPolling()

				.done()

		, 1000



class Iconto.REST.TaskCollection extends Iconto.REST.RESTCollection
	url: 'task'
	model: Iconto.REST.Task