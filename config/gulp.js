import _ from 'lodash';
import del from 'del';
import webpack from 'webpack';
import protractor from 'protractor/lib/launcher';
import HotServer from 'webpack-dev-server';
import browsersync from 'browser-sync';
import spa from 'browser-sync-spa';
import {Server as KarmaServer} from 'karma';
import {task, parallel, series} from 'gulp';

import wpSetup from './webpack';
import bsSetup from './browsersync';
import protSetup from './protractor';
import karmaSetup from './karma';

const SPA = true;
const DEV = process.env.NODE_ENV !== 'production';
const PORT = process.env.PORT || 9001;

task('clean', () => del('dist'));

task('hot', () => {
	const compiler = webpack(wpSetup({
		dev: true,
		hot: true,
		port: PORT
	}));
	const server = new HotServer(compiler);
	server.listen(PORT);
});

task('build', done => {
	if (DEV) done = _.once(done);
	webpack(wpSetup({
		dev: DEV,
		hot: false
	}), (err, stats) => {
		if (err) console.error(err);
		console.log(stats.toString({colors: true}));
		done();
	});
});

task('serve', () => {
	const server = browsersync.create();
	if (SPA) {
		server.use(spa({
			selector: '[ng-app]'
		}));
	}
	server.init(bsSetup({
		dev: DEV,
		port: PORT
	}));
});

task('test', done => {
	const server = new KarmaServer(karmaSetup({
		dev: DEV,
		real: false
	}), (code) => {
		if (!DEV) done();
		console.log('Karma has exited with ' + code);
		process.exit(code);
	});
	server.start();
});

task('e2e', done => {
	protractor.init('', protSetup({
		port: PORT
	}));
	done();
});

task('default', series(
	'clean',
	parallel('build', 'serve')
));
