console.info('APP:');

import {browser as _templateSettings} from '../../config/ejs';
import _ from 'lodash';
_.templateSettings = _templateSettings;

// // console.log(require('jquery'));
// // _.templateSettings.imports
// _.templateSettings.interpolate=/\{\{([\s\S]+?)\}\}/;
// _.templateSettings.escape = /\{\{[-|=]([\s\S]+?)\}\}/;
// _.templateSettings.evaluate = /\{\{([\s\S]+?)\}\}/;

// import './app.styl';
// import 'modules/calc/calc.module';
document.body.innerHTML += require('./tpl.ejs')({'hello from Mary': 'hi hi hi!'});