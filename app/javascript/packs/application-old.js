import '../shared/polyfills';
import Turbolinks from 'turbolinks';
import jQuery from 'jquery';
import start from 'better-ujs';

import ActiveStorage from '../shared/activestorage/ujs';

import '../shared/sentry';
import '../shared/rails-ujs-fix';
import '../shared/autocomplete';

import '../old_design/carto';

// Start Rails helpers
start();
Turbolinks.start();
ActiveStorage.start();

// Disable jQuery-driven animations during tests
if (process.env['RAILS_ENV'] === 'test') {
  jQuery.fx.off = true;
}

// Export jQuery globally for legacy Javascript files used in the old design
window.$ = jQuery;
window.jQuery = jQuery;
