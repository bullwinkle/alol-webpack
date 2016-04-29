@Iconto.module 'shared.helpers', (Helpers) ->
	_.extend Helpers,
		environment: =>
			# returns a string depending on environment
			# dev | stage | (empty string for production)
			apiUrl = window.ICONTO_API_URL
			if apiUrl.indexOf('dev') >= 0 then 'dev' else if apiUrl.indexOf('stage') >= 0 then 'stage' else ''

		datetime:
			getDateString: (time) ->
				if !!!time then return ""
				d = new Date(time * 1000)
				day = d.getDate()
				month = d.getMonth() + 1
				year = d.getFullYear()
				day = "0#{day}" if day < 10
				month = "0#{month}" if month < 10
				return "#{day}.#{month}.#{year}"

		phone:
			format: (phone) =>
				if phone.length is 10 #russian number
					phone = phone.replace(/^(\d{3})(\d{3})(\d{2})(\d{2})$/, '($1) $2-$3-$4')
				else
					phone
			format7: (phone) =>
				if /^7\d{10}$/.test phone  #russian number with leading 7
					phone = phone.replace(/^7(\d{3})(\d{3})(\d{2})(\d{2})$/, '($1) $2-$3-$4')
				else
					Helpers.phone.format(phone)
			parse: (phone) =>
				"#{phone.replace(/[\(,\),\-, ]+/g, '')}"

		regexps:
			phone: /^7\d{10}$/

		money: (value) ->
			accounting.formatNumber(value, 2, ' ', '.')

		user:
			getName: (user) ->
				if user.first_name or user.last_name
					"#{user.first_name} #{user.last_name}"
				else if user.phone
					"+#{user.phone}"
				else if user.nickname
					"#{user.nickname}"
				else
					"Аноним ##{user.id || 0}"

		distance:
			format: (distance) ->
				if distance >= 10000 #over 10 km
					"#{Math.round(distance / 1000)} км"
				else if distance >= 1000
					"#{(distance / 1000).toFixed(1)} км"
				else
					"#{Math.round(distance)} м"

		declension: (number, designation) => #designation: [1, 2, many]
			titles = designation
			cases = [2, 0, 1, 1, 1, 2]
			number = Math.floor(Math.abs(number))
			`titles[(number % 100 > 4 && number % 100 < 20) ? 2 : cases[(number % 10 < 5) ? number % 10 : 5]]`

		navigation:
			tryNavigate: (_url, target = '_blank') =>
				url = Iconto.shared.helpers.navigation.parseUri _url
				if document.location.host is url.host #same host, navigate
					url = "#{url.pathname}#{url.search}"
					Iconto.shared.router.navigate url, trigger: true
				else #different hosts, redirect
					window.open url.href, target

		# uses parseUri
			getQueryParams: (uri = window.location.search) =>
				result = {}

				decode = (s) -> decodeURIComponent s.replace(/\+/g, ' ')
				if uri[0] isnt '?' then uri = Iconto.shared.helpers.navigation.parseUri(uri).search
				uri.replace new RegExp("([^?=&]+)(=([^&]*))?", "g"), ($0, $1, $2, $3) ->
					key = decode($1)
					value = decode($3)
					try value = JSON.parse(value)
					result[key] = value
				result

		# uses getQueryParams and $.param
			setQueryParams: (key, value, updateUri = false, uri = (window.location.pathname + window.location.search)) ->
				encode = (s) -> encodeURIComponent s # not rally nedd, because of $.param
				# convert any type of params to key - value
				params = Iconto.shared.helpers.navigation.getQueryParams()
				for paramKey, paramValue of params
					if _.isArray(paramValue) or _.isObject(paramValue)
						paramValue = JSON.stringify paramValue
						params[paramKey] = paramValue

				if _.isString(value)
					if value is 'undefined'
						value = null

				else if _.isArray(value) or _.isObject(value)
					unless _.isEmpty(value)
						value = JSON.stringify value
					else
						value = null

				if value
					params[key] = value
				else
					delete params[key]

				paramsString = $.param params # all incoding is here
				paramsString = if paramsString.length > 0 then "?#{paramsString}" else ''

				if updateUri and window.history?.pushState
					window.history.replaceState null, null, "#{window.location.pathname}#{paramsString}"
				else
					paramsString

			parseUri: (uri = window.location.href) =>
				uri = uri.replace(/\s/g, '')
				uri = uri.replace(/^\/\//, '')
				uri = "http://#{uri}" unless /^http[s]?:\/\//.test uri
				res = Url.parse uri, true
				res.hostname = Iconto.shared.helpers.toUnicode(res.hostname)
				res.host = "#{res.hostname}#{if res.port then ":#{res.port}" else ''}"
				res.href = res.format()
				res

			formatUri: (urlObj) =>
				unless _.isEmpty urlObj.query
					delete urlObj.search
				Url.format urlObj

			joinPath: ->
				# Split the inputs into a list of path commands.
				parts = []
				i = 0
				l = arguments.length
				while i < l
					parts = parts.concat(arguments[i].split('/'))
					i++
				# Interpret the path commands to get the new resolved path.
				newParts = []
				i = 0
				l = parts.length
				while i < l
					part = parts[i]
					# Remove leading and trailing slashes
					# Also remove "." segments
					if !part or part == '.'
						i++
						continue
					# Interpret ".." to pop the last segment
					if part == '..'
						newParts.pop()
					else
						newParts.push part
					i++
				# Preserve the initial slash if there was one.
				if parts[0] == ''
					newParts.unshift ''
				# Turn back into a single string path.
				newParts.join('/') or (if newParts.length then '/' else '.')

			navigateBack: (defaultRoute="/wallet/cards", queryRouteParam='query.from', navigateOptions) ->
				parsedUrl = Iconto.shared.helpers.navigation.parseUri()
				fromRoute = _.get parsedUrl, queryRouteParam
				route = fromRoute or defaultRoute
				Iconto.shared.router.navigate route, trigger: true

		sms:
			gsm7bitChars: "\\\@£\$¥èéùìòÇ\nØø\rÅåΔ_ΦΓΛΩΠΨΣΘΞÆæßÉ !\"#¤%&'()*+,-./0123456789:;<=>?¡ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ§¿abcdefghijklmnopqrstuvwxyzäöñüà^{}[~]|€"

			is7bit: (symbol) ->
				Helpers.sms.gsm7bitChars.search(symbol) + 1 != 0 && symbol != "\\"

			countSms: (str) ->
				length = str.length
				count = 1
				if _.every str.split(''), Helpers.sms.is7bit
					count = Math.ceil length / 153 if length > 160
				else
					count = Math.ceil length / 67 if length > 70
				count

		card:
			validateLuhn: (number) ->
				# https://gist.github.com/elliot/1164554
				odd = true
				sum = _(number.toString().split '').reduceRight (total, digit) ->
					digit = parseInt(digit)
					digit *= 2 if (odd = !odd)
					digit -= 9 if digit > 9
					total + digit
				, 0
				sum % 10 == 0

		device:
			isMobile: ->
				navigator = window.navigator.userAgent or window.navigator.vendor or window.opera
				(jQuery.browser = jQuery.browser or {}).mobile = /(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino/i.test(navigator) or /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(navigator.substr(0,
						4))
				jQuery.browser.mobile
			isIE: ->
				navigator.appName is 'Microsoft Internet Explorer'

			isIos: ->
				navigator.userAgent?.match /ip(hone|od|ad)/i

		color:
			luminance: (hex, lum) ->
				# validate hex string
				hex = String(hex).replace(/[^0-9a-f]/g, "")
				hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2] if hex.length < 6
				lum = lum or 0

				# convert to decimal and change luminosity
				rgb = "#"
				i = 0
				while i < 3
					c = parseInt(hex.substr(i * 2, 2), 16)
					c = Math.round(Math.min(Math.max(0, c + (c * lum)), 255)).toString(16)
					rgb += ("00" + c).substr(c.length)
					i++
				rgb

		string:
			replaceCharAtIndex: (string, index, character) ->
				string.substr(0, index) + character + string.substr(index + character.length)
			toCamelCase: (string) ->
				string.replace(/(\-[a-z])/g, ($1) -> $1.toUpperCase().replace('-', ''))
			toDashCase: (string) ->
				string.replace(/([A-Z])/g, ($1) -> '-' + $1.toLowerCase())
			htmlToText: (html) -> #http://stackoverflow.com/questions/3455931/extracting-text-from-a-contenteditable-div
				pre = $('<pre />').html html
				pre.find('div').replaceWith -> "\n#{@innerHTML}" #webkit
				pre.find('p').replaceWith -> "#{@innerHTML}\n" #ie
				pre.find('br').replaceWith '\n' #mozilla, opera, ie
				text = pre.text()
				text = text.replace /(\n)+/g, '\n'
				text = text.replace /(\s)+/g, '$1'
				text.trim()
			stripTags: (html) ->
				$('<div></div>').html(html).text()

			escape: (text) -> #from ejs escape fn
				span = document.createElement 'span'
				span.innerHTML = text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g,
					'&quot;').replace(/'/g, '&#x27;').replace(/\//g, '&#x2F;')
				innerText = if span.innerText then 'innerText' else 'textContent'
				span[innerText]

			urlify: do -> #test - http://ha.ckers.org/xssAttacks.xml
				urlRegex = /(https?:&#x2F;&#x2F;[^\s]+)/g
				(text, classNames, attributes) -> #http://stackoverflow.com/a/1500501/1961479
					attributes ||= {}
					attributes['data-bypass'] = true if _.isUndefined(attributes['data-bypass'])
					attributes.target = '_blank' if _.isUndefined(attributes.target)
					attributes = _.map(attributes, (value, key) -> "#{key}=\"#{value}\"").join(' ')

					classNames = "class=\"#{classNames}\" " if classNames

					escaped = Helpers.string.escape(text)
					escaped.replace urlRegex, (url) ->
						'<a ' + classNames + 'href="' + url + '" ' + attributes + '>' + url + '</a>'

			linkify: (text) =>
				if text
					text = Helpers.string.escape(text)
					text = text.replace /((https?\:\/\/)|(www\.))(\S+)(\w{2,4})(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/gi, (url) ->
						full_url = url
						full_url = 'http://' + full_url unless full_url.match('^https?:\/\/')
						a = document.createElement('a')
						a.href = url
						'<a href="' + full_url + '" data-bypass target="_blank" class="theme">' + a.host + a.pathname + '</a>';
				text

			replaceEntities: `function (str) {
				return $('<textarea>' + ((str || '').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')) + '</textarea>').val();
			}`

			indexOf: `function (arr, value, from) {
				for (var i = from || 0, l = (arr || []).length; i < l; i++) {
					if (arr[i] == value) return i;
				}
				return -1;
			}`


			clean: `function (str) {
				return str ? str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#039;') : '';
			}`

			vkLinkify: `
				function (message) {
					message = (message || '').replace(/(^|[^A-Za-z0-9À-ßà-ÿ¸¨\-\_])(https?:\/\/)?((?:[A-Za-z\$0-9À-ßà-ÿ¸¨](?:[A-Za-z\$0-9\-\_À-ßà-ÿ¸¨]*[A-Za-z\$0-9À-ßà-ÿ¸¨])?\.){1,5}[A-Za-z\$ðôóêîíëàéíñòÐÔÓÊÎÍËÀÉÍÑÒ\-\d]{2,22}(?::\d{2,5})?)((?:\/(?:(?:\&amp;|\&#33;|,[_%]|[A-Za-z0-9À-ßà-ÿ¸¨\-\_#%?+\/\$.~=;:]+|\[[A-Za-z0-9À-ßà-ÿ¸¨\-\_#%?+\/\$.,~=;:]*\]|\([A-Za-z0-9À-ßà-ÿ¸¨\-\_#%?+\/\$.,~=;:]*\))*(?:,[_%]|[A-Za-z0-9À-ßà-ÿ¸¨\-\_#%?+\/\$.~=;:]*[A-Za-z0-9À-ßà-ÿ¸¨\_#%?+\/\$~=]|\[[A-Za-z0-9À-ßà-ÿ¸¨\-\_#%?+\/\$.,~=;:]*\]|\([A-Za-z0-9À-ßà-ÿ¸¨\-\_#%?+\/\$.,~=;:]*\)))?)?)/ig, function () {
						var matches = Array.prototype.slice.apply(arguments),
								prefix = matches[1] || '',
								protocol = matches[2] || 'http://',
								domain = matches[3] || '',
								url = domain + (matches[4] || ''),
								full = (matches[2] || '') + matches[3] + matches[4];

						if (domain.indexOf('.') == -1 || domain.indexOf('..') != -1) return matches[0];
						var topDomain = domain.split('.').pop();
						if (topDomain.length > 7 || Helpers.string.indexOf('info,name,academy,aero,arpa,coop,media,museum,mobi,travel,xxx,asia,biz,com,net,org,gov,mil,edu,int,tel,ac,ad,ae,af,ag,ai,al,am,an,ao,aq,ar,as,at,au,aw,ax,az,ba,bb,bd,be,bf,bg,bh,bi,bj,bm,bn,bo,br,bs,bt,bv,bw,by,bz,ca,cc,cd,cf,cg,ch,ci,ck,cl,cm,cn,co,cr,cu,cv,cx,cy,cz,de,dj,dk,dm,do,dz,ec,ee,eg,eh,er,es,et,eu,fi,fj,fk,fm,fo,fr,ga,gd,ge,gf,gg,gh,gi,gl,gm,gn,gp,gq,gr,gs,gt,gu,gw,gy,hk,hm,hn,hr,ht,hu,id,ie,il,im,in,io,iq,ir,is,it,je,jm,jo,jp,ke,kg,kh,ki,km,kn,kp,kr,kw,ky,kz,la,lb,lc,li,lk,lr,ls,lt,lu,lv,ly,ma,mc,md,me,mg,mh,mk,ml,mm,mn,mo,mp,mq,mr,ms,mt,mu,mv,mw,mx,my,mz,na,nc,ne,nf,ng,ni,nl,no,np,nr,nu,nz,om,pa,pe,pf,pg,ph,pk,pl,pm,pn,pr,ps,pt,pw,py,qa,re,ro,ru,rs,rw,sa,sb,sc,sd,se,sg,sh,si,sj,sk,sl,sm,sn,so,sr,ss,st,su,sv,sx,sy,sz,tc,td,tf,tg,th,tj,tk,tl,tm,tn,to,tp,tr,tt,tv,tw,tz,ua,ug,uk,um,us,uy,uz,va,vc,ve,vg,vi,vn,vu,wf,ws,ye,yt,yu,za,zm,zw,ðô,óêð,ñàéò,îíëàéí,ñðá,cat,pro,local'.split(','), topDomain) == -1) {
							if (!/^[a-zA-Z]+$/.test(topDomain) || !matches[2]) {
								return matches[0];
							}
						}

						if (matches[0].indexOf('@') != -1) {
							return matches[0];
						}
						try {
							full = decodeURIComponent(full);
						} catch (e) {
						}

						if (full.length > 55) {
							full = full.substr(0, 53) + '..';
						}
						full = Helpers.string.clean(full).replace(/&amp;/g, '&');
						if (window.location.host == domain) {
							var internalUrl = Helpers.navigation.joinPath('/', _.escape(matches[4] || ''));
							var internal = prefix + '<a href="' + internalUrl + '" class="theme">' + full + '</a>';
							return internal;
						} else {
							var external = prefix + '<a href="' + protocol + Helpers.string.replaceEntities(url) + '" target="_blank" data-bypass class="theme">' + full + '</a>';
							return external;
						}
					});

					return message;
				}
			`

		dateValidation:
			yearValidation: (date) =>
				moment(date) > moment('2010-01-01')

		image: do ->
			#variables
			ratio = window.devicePixelRatio or 1
			small = Math.round(ratio * 50)
			medium = Math.round(ratio * 100)
			large = Math.round(ratio * 200)

			#result
			resize: (url, format = Helpers.image.FORMAT_SQUARE_MEDIUM) ->
				if url
					urlObj = Url.parse url, true
					unless _.isEmpty urlObj.query
						delete urlObj.search
					_.set urlObj, 'query.resize', "#{format}q[100]e[true]"
					Url.format urlObj
				else
					''

			anonymous: ->
				index = Math.floor(Math.random() * window.ICONTO_USER_IMAGES.length);
				window.ICONTO_USER_IMAGES[index]

			FORMAT_SQUARE_SMALL: "w[#{small}]h[#{small}]"
			FORMAT_SQUARE_MEDIUM: "w[#{medium}]h[#{medium}]"
			FORMAT_SQUARE_LARGE: "w[#{large}]h[#{large}]"

		legal:
			getLegal: (legal, options) ->
				leadingComma = options?.leadingComma || false

				if legal and legal.id
					legal.type = legal.type || Iconto.REST.LegalEntity::defaults.type
					self = "#{Iconto.REST.LegalEntity.LEGAL_TYPES[legal.type - 1]} \"#{legal.name}\""
					self = ", #{self}" if leadingComma
					self
				else
					""

		transitionEndEventName: (=>
			i = undefined
			el = document.createElement('div')
			transitions =
				'transition': 'transitionend'
				'OTransition': 'otransitionend'
				'MozTransition': 'transitionend'
				'WebkitTransition': 'webkitTransitionEnd'
			for i of transitions
				`i = i`
				if transitions.hasOwnProperty(i) and el.style[i] != undefined
					return transitions[i]
			return)()

		inherit: (parent, extender) ->
			parent = _.clone parent
			result = if extender and _.isObject extender
				_.extend parent, extender
			else
				parent
			result

		toUnicode: (value) ->
			try
				punycode.toUnicode value
			catch err
				console.warn err
				value


		prepareData: (categories) => # prepare grouped object of flattended array with ids and parent_ids
			goodsTree = []
			subCategories = []
			for category in categories
				if +category.parent_id
					subCategories.push category
				else
					goodsTree.push category

			for subCategory in subCategories
				do (subCategory) =>
					rootCategory = _.find categories, (category) => +category.id is +subCategory.parent_id
					unless rootCategory
						return console.warn "faild to find parent_category with id=#{subCategory.parent_id} for category with id=#{subCategory.id}"
					rootCategory.subCategories = rootCategory.subCategories or []
					rootCategory.subCategories.push subCategory
			goodsTree

		makeCategoriesTree: (dataArray, parentIdKey='parent_id', idKey='id', childrenKey="children") =>
			groupedByParents = _.groupBy dataArray, parentIdKey
			categoriesById = _.indexBy dataArray, idKey
			_.each _.omit(groupedByParents, '0'), (children, parentId) =>
				_.set categoriesById, "[#{parentId}].#{childrenKey}", children
			return groupedByParents['0']

		openNativePopup: (options = {}) =>
			screenX = if typeof window.screenX != 'undefined' then window.screenX else window.screenLeft
			screenY = if typeof window.screenY != 'undefined' then window.screenY else window.screenTop
			outerWidth = if typeof window.outerWidth != 'undefined' then window.outerWidth else document.body.clientWidth
			outerHeight = if typeof window.outerHeight != 'undefined' then window.outerHeight else document.body.clientHeight - 22
			width = options.width or (outerWidth * 0.8)
			height = options.height or (outerHeight * 0.8)
			left = parseInt(screenX + (outerWidth - width) / 2, 10)
			top = parseInt(screenY + (outerHeight - height) / 2.5, 10)
			features = 'menubar=no,toolbar=no,resizable=yes,scrollbars=yes,width=' + width + ',height=' + height + ',left=' + left + ',top=' + top
			window.open(options.url, options.popupName or '', features)

		messages:
			openChat: ({userId, addressId, companyId, reviewId, fromOffice}) ->
				userId = userId or Iconto.api.userId

				roomView = new Iconto.REST.RoomView()
				reasons = []
				unless fromOffice
					reasons.push {type: Iconto.REST.Reason.TYPE_USER, user_id: userId}
				if addressId
					reasons.push {type: Iconto.REST.Reason.TYPE_ADDRESS, address_id: addressId}
				else if companyId
					reasons.push {type: Iconto.REST.Reason.TYPE_COMPANY, company_id: companyId}
				else if reviewId
					reasons.push {type: Iconto.REST.Reason.TYPE_REVIEW, review_id: reviewId}
				else
					return false
				if fromOffice
					reasons.push {type: Iconto.REST.Reason.TYPE_USER, user_id: userId}
				roomView.save(reasons: reasons)

			createServiceChat: =>
				companyId = 2775
				userId = Iconto.api.userId
				Iconto.shared.helpers.messages.openChat {userId, companyId}

		# recourcive search in Backbone tree-views by model.id
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