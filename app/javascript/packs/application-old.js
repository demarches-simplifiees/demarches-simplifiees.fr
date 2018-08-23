import Turbolinks from 'turbolinks';
import Rails from 'rails-ujs';
import ActiveStorage from '../shared/activestorage/ujs';
import jQuery from 'jquery';

// Include runtime-polyfills for older browsers.
// Due to .babelrc's 'useBuiltIns', only polyfills actually
// required by the browsers we support will be included.
import 'babel-polyfill';

import '../shared/sentry';
import '../shared/rails-ujs-fix';
import '../shared/autocomplete';

// Start Rails helpers
Rails.start();
Turbolinks.start();
ActiveStorage.start();

// Disable jQuery-driven animations during tests
if (process.env['RAILS_ENV'] === 'test') {
  jQuery.fx.off = true;
}

// Export jQuery globally for legacy Javascript files used in the old design
jQuery.rails = Rails;
window.$ = jQuery;
window.jQuery = jQuery;
