module.exports = {
	loader: {
		interpolate: /\{\{%=([\s\S]+?)\}\}/,
		escape: /\{\{[-|=]([\s\S]+?)\}\}/,
		evaluate: /\{\{([\s\S]+?)\}\}/
	},
	browser: {
		escape: /<@-([\s\S]+?)@>/g,
		evaluate: /<@([\s\S]+?)@>/g,
		interpolate: /<@=([\s\S]+?)@>/g
	}
}