class Iconto.REST.Attachment extends Iconto.REST.WSModel

	@TYPE_IMAGE = TYPE_IMAGE = 'ATTACHMENT_TYPE_IMAGE'
	@TYPE_AUDIO = TYPE_AUDIO = 'ATTACHMENT_TYPE_AUDIO'
	@TYPE_VIDEO = TYPE_VIDEO = 'ATTACHMENT_TYPE_VIDEO'
	@TYPE_DOCUMENT = TYPE_DOCUMENT = 'ATTACHMENT_TYPE_DOCUMENT'
	@TYPE_REASON = TYPE_REASON = 'ATTACHMENT_TYPE_REASON'
	@TYPE_COUPON = TYPE_COUPON = 'ATTACHMENT_TYPE_COUPON'
	@TYPE_TRANSACTION = TYPE_TRANSACTION = 'ATTACHMENT_TYPE_TRANSACTION'
	@TYPE_SPOT = TYPE_SPOT = 'ATTACHMENT_TYPE_SPOT'
	@TYPE_DELIVERY = TYPE_DELIVERY = 'ATTACHMENT_TYPE_DELIVERY'
	@TYPE_META = TYPE_META = 'ATTACHMENT_TYPE_META'

	defaults:
		type: 0

	@getTypeString: (type) ->
		switch type
			when TYPE_IMAGE then 'Фотография'
			when TYPE_AUDIO then 'Аудиозапись'
			when TYPE_VIDEO then 'Видеозапись'
			when TYPE_DOCUMENT then 'Документ'
			when TYPE_COUPON then 'Купон'
			when TYPE_TRANSACTION then 'Транзакция'
			when TYPE_SPOT then 'Точка обратной связи'
			when TYPE_DELIVERY then 'Рассылка'
			else
				'Вложение'

class Iconto.REST.AttachmentCollection extends Iconto.REST.WSCollection
	model: Iconto.REST.Attachment