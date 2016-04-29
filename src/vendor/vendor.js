console.info('VENDOR:');

// console.log(require('jquery'));
require('lodash');
import {browser as _templateSettings} from '../../config/ejs';
_.templateSettings = _templateSettings;

window.jQuery = window.$ = require('jquery');
require('jquery.cookie');
require('jquery.scrollTo');
require('jquery.scrollIntoView');
require('jquery.minicolors');
require('jquery.mousewheel');
// require('./modernizr-custom'); // it places <head> after <body>

require('backbone/backbone');
require('backbone/backbone.wreqr');
require('backbone/backbone.deep-model.js');
require('backbone/backbone.babysitter');
require('backbone/backbone-validation');
require('backbone/backbone.epoxy');
require('backbone.modal/backbone.modal');
require('backbone/backbone.marionette');
require('backbone.modal/backbone.marionette.modals');

require('bluebird');

require('selectordie-custom');

require('fastclick');
require('accounting');
require('moment');
require('foundation-sites');
// rescript!quire('./foundation/foundation.offcanvas');
// rescript!quire('./foundation/foundation.dropdown');
// rescript!quire('./foundation/foundation.tooltip');
// rescript!quire('./foundation-datepicker');
//
// console.warn(require('script!./socket.io.js'));
require('socket.io-client');

require('intercom');
//https://github.com/bestiejs/punycode.js
require('punycode');

//https://github.com/MohammadYounes/AlertifyJS/
require('alertify');

require('crypto');

// https://github.com/fengyuanchen/cropper
require('cropper/cropper');

// from nodejs core modules
require('url');

//https://github.com/alexgibson/notify.js
require('notify');

// https://www.npmjs.com/package/virtual-select
require('virtual-select/virtual-select-jquery.min');
require('slick');