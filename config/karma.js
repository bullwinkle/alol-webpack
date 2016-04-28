import wpSetup from './webpack';

const defaults = wpSetup({
	dev: true,
	test: true
});

const wpConfig = Object.assign(defaults, {
	entry: {},
	output: {}
});

export default function ({dev, real}) {

	let cfg = {
		autoWatch: dev,
		singleRun: !dev,
		frameworks: ['chai', 'jasmine'],
		reporters: ['mocha'],
		browsers: ['PhantomJS'],
		files: [
			'./test/unit/index.js',
			'./test/unit/**/*.js',
			'./src/**/*.spec.js'
		],
		preprocessors: {
			'./src/**/*.js': ['webpack', 'sourcemap'],
			'./test/**/*.js': ['webpack', 'sourcemap']
		},
		plugins: [
			'karma-chai',
			'karma-mocha',
			'karma-webpack',
			'karma-jasmine',
			'karma-mocha-reporter',
			'karma-sourcemap-loader',
			'karma-phantomjs-launcher'
		],
		webpack: wpConfig,
		webpackMiddleware: {
			noInfo: true
		}
	};

	if (real) {
		cfg.browsers = [
			'Chrome',
			'Safari',
			'Firefox'
		];
		cfg.plugins.push('karma-safari-launcher');
		cfg.plugins.push('karma-chrome-launcher');
		cfg.plugins.push('karma-firefox-launcher');
	}

	return cfg;

}