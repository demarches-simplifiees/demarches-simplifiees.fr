import Turbolinks from 'turbolinks';
import Rails from 'rails-ujs';
import ActiveStorage from '../shared/activestorage/ujs';
import Chartkick from 'chartkick';
import Highcharts from 'highcharts';
import Bloodhound from 'bloodhound-js';
import jQuery from 'jquery';

// Include runtime-polyfills for older browsers.
// Due to .babelrc's 'useBuiltIns', only polyfills actually
// required by the browsers we support will be included.
import 'babel-polyfill';

import 'typeahead.js';

import '../shared/sentry';
import '../shared/rails-ujs-fix';

// Start Rails helpers
Chartkick.addAdapter(Highcharts);
Rails.start();
Turbolinks.start();
ActiveStorage.start();

// Disable jQuery-driven animations during tests
if (process.env['RAILS_ENV'] === 'test') {
  jQuery.fx.off = true;
}

// Expose globals
window.Bloodhound = Bloodhound;
window.Chartkick = Chartkick;
// Export jQuery globally for legacy Javascript files used in the old design
jQuery.rails = Rails;
window.$ = jQuery;
window.jQuery = jQuery;
