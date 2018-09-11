import '../shared/polyfills';
import Turbolinks from 'turbolinks';
import Rails from 'rails-ujs';
import ActiveStorage from '../shared/activestorage/ujs';
import Chartkick from 'chartkick';
import Highcharts from 'highcharts';
import jQuery from 'jquery';

import '../shared/sentry';
import '../shared/rails-ujs-fix';
import '../shared/safari-11-file-xhr-workaround';
import '../shared/autocomplete';
import '../shared/remote-input';

import '../new_design/spinner';
import '../new_design/dropdown';
import '../new_design/form-validation';
import '../new_design/carto';
import '../new_design/select2';

import '../new_design/champs/linked-drop-down-list';

import { toggleCondidentielExplanation } from '../new_design/avis';
import { scrollMessagerie } from '../new_design/messagerie';
import { showMotivation, motivationCancel } from '../new_design/state-button';
import { toggleChart } from '../new_design/toggle-chart';

// This is the global application namespace where we expose helpers used from rails views
const DS = {
  toggleCondidentielExplanation,
  scrollMessagerie,
  showMotivation,
  motivationCancel,
  toggleChart
};

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
window.DS = window.DS || DS;
window.Chartkick = Chartkick;
