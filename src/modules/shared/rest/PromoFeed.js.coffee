class Iconto.REST.PromoFeed extends Iconto.REST.RESTModel
	@OBJECT_TYPE_PROMOTION  	= 1
	@OBJECT_TYPE_CASHBACK   	= 2
	@OBJECT_TYPE_CASHBACK_GROUP	= 3

	urlRoot: 'promo-feed'

	defaults:
		id: 0
		company_id: 0
		object_id: 0
		object_type: 0
		category_id: 0
		created_at: 0
		is_liked: false
		is_favourite: false
		likes_count: 0
		favourites_count: 0
		is_top: false
		is_recommended: false
		cashback_max_percent: 0 #need for object_type 3
		cashback_count: 0 		#need for object_type 3
		deleted: false

class Iconto.REST.PromoFeedCollection extends Iconto.REST.RESTCollection
	url: 'promo-feed'
	model: Iconto.REST.PromoFeed
