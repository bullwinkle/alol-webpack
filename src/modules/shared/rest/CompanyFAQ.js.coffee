class Iconto.REST.CompanyFAQ extends Iconto.REST.RESTModel

	@TYPE_CATEGORY = TYPE_CATEGORY = 'c'
	@TYPE_QUESTION = TYPE_QUESTION = 'q'

	constructor: ->
		super
		_.extend @, Backbone.Validation.mixin

	urlRoot: 'company-faq'
	defaults:
		id: 0
		title: ""
		answer: ""
		type: TYPE_QUESTION
		company_id: 0
		parent_id: 0
#		updated_at: 0
#		deleted: false
		children: [] # this field is created by collection parse function

		# needed just for binding
		isOpened: false

	validation: ->
		title:
			required: true
			minLength: 1
		answer:
			if @get('type') is TYPE_QUESTION
				required: true

	serialize: (obj) =>
		unless obj.id then delete obj.id
		delete obj.updated_at
		delete obj.deleted
		delete obj.isOpened
		delete obj.children
		obj

class Iconto.REST.CompanyFAQCollection extends Iconto.REST.RESTCollection
	url: 'company-faq'
	model: Iconto.REST.CompanyFAQ
	parse: (arr) =>
		@buildTree arr

	fetchCategories: (query) =>
		(new @constructor()).fetch query
		.then (res) =>
			categories = _.filter res, (el) => el.type is @model.TYPE_CATEGORY
			categories
		.then (res) =>
			@parse res

	fetchQuestions: (query) =>
		(new @constructor()).fetch query
		.then (res) =>
			questions = _.filter res, (el) => el.type is @model.TYPE_QUESTION
			questions

	buildTree: (dataArray, parentIdKey='parent_id', idKey='id') =>
		# taken from  Iconto.shared.helpers.makeCategoriesTree
		groupedByParents = _.groupBy dataArray, parentIdKey
		indexedCategories = _.indexBy dataArray, idKey
		_.each _.omit(groupedByParents, '0'), (children, parentId) =>
			_.set indexedCategories, "[#{parentId}].children", children
		return groupedByParents['0']

	comparator:(next) ->
		# sort by type, then by title
		# the arrow must be single!
		[next.get('type'),next.get('title')]