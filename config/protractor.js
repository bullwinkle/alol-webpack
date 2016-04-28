export default function ({port}) {

	let cfg = {
		debug: true,
		seleniumAddress: 'http://localhost:4444/wd/hub',
		specs: [
			process.cwd() + '/test/e2e/*.js',
			process.cwd() + '/src/app/*.e2e.js'
		],
		framework: 'jasmine'
	};

	cfg.baseUrl = `http://localhost:${port}`;

	cfg.jasmineNodeOpts = {
		defaultTimeoutInterval: 20000,
		showTiming: true,
		isVerbose: true,
		showColors: true
	};

	return cfg;

};