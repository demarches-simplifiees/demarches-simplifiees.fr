import '../shared/polyfills';
import Rails from '@rails/ujs';
import * as ActiveStorage from '@rails/activestorage';
import jQuery from 'jquery';

import '../shared/page-update-event';
import '../shared/activestorage/ujs';
import '../shared/rails-ujs-fix';
import '../shared/safari-11-file-xhr-workaround';
import '../shared/remote-input';
import '../shared/franceconnect';

// Start Rails helpers
Rails.start();
ActiveStorage.start();

// Disable jQuery-driven animations during tests
if (process.env['RAILS_ENV'] === 'test') {
  jQuery.fx.off = true;
}

// Export jQuery globally for legacy Javascript files used in the old design
jQuery.rails = Rails;
window.$ = jQuery;
window.jQuery = jQuery;
