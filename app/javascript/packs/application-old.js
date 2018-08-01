import Turbolinks from 'turbolinks';
import Rails from 'rails-ujs';
import * as ActiveStorage from 'activestorage';
import Chartkick from 'chartkick';
import Highcharts from 'highcharts';
import Bloodhound from 'bloodhound-js';
import jQuery from 'jquery';

import 'select2';
import 'typeahead.js';

import '../shared/rails-ujs-fix';
import '../shared/direct-uploads';

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
window.$ = jQuery;
window.jQuery = jQuery;
