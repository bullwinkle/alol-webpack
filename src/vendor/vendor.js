console.info('VENDOR:');

// console.log(require('jquery'));
import {browser as _templateSettings} from '../../config/ejs';
import _ from 'lodash';
_.templateSettings = _templateSettings;
// _.templateSettings.imports
// require('lodash').templateSettings.interpolate=/\{\{([\s\S]+?)\}\}/;
// require('lodash').templateSettings.escape = /\{\{[-|=]([\s\S]+?)\}\}/;
// require('lodash').templateSettings.evaluate = /\{\{([\s\S]+?)\}\}/;

// var o = {interpolate: /\{\{([\s\S]+?)\}\}/,	escape: /\{\{[-|=]([\s\S]+?)\}\}/,evaluate: /\{\{([\s\S]+?)\}\}/}

// _.templateSettings.variable
// EJS.evaluation_pattern    = /\{\{([\s\S]+?)\}\}/
// EJS.escape_pattern = /\{\{[-|=]([\s\S]+?)\}\}/
// EJS.interpolation_pattern = /\{\{%=([\s\S]+?)\}\}/