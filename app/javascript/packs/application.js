import Turbolinks from 'turbolinks';
import Rails from 'rails-ujs';
import * as ActiveStorage from 'activestorage';

import Chartkick from 'chartkick';
import Highcharts from 'highcharts';

import 'select2';
import 'typeahead.js';

import '../shared/rails-ujs-fix';
import '../shared/direct-uploads';

import '../new_design/buttons';
import '../new_design/form-validation';
import '../new_design/carto';

import '../new_design/champs/address';
import '../new_design/champs/dossier-link';
import '../new_design/champs/linked-drop-down-list';
import '../new_design/champs/multiple-drop-down-list';
import '../new_design/champs/siret';

import { toggleCondidentielExplanation } from '../new_design/avis';
import { togglePrintMenu } from '../new_design/dossier';
import { toggleHeaderMenu } from '../new_design/header';
import { scrollMessagerie } from '../new_design/messagerie';
import { showMotivation, motivationCancel } from '../new_design/state-button';
import { toggleChart } from '../new_design/toggle-chart';

// This is the global application namespace where we expose helpers used from rails views
const DS = {
  toggleCondidentielExplanation,
  togglePrintMenu,
  toggleHeaderMenu,
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

// Expose globals
window.DS = window.DS || DS;
window.Chartkick = Chartkick;
