import '../shared/polyfills';
import Turbolinks from 'turbolinks';
import Rails from 'rails-ujs';
import * as ActiveStorage from 'activestorage';
import Chartkick from 'chartkick';
import Highcharts from 'highcharts';

import ReactUJS from '../shared/react-ujs';
import reactComponents from '../shared/react-components';

import '../shared/activestorage/ujs';
import '../shared/rails-ujs-fix';
import '../shared/safari-11-file-xhr-workaround';
import '../shared/autocomplete';
import '../shared/remote-input';
import '../shared/franceconnect';
import '../shared/toggle-target';

import '../new_design/dropdown';
import '../new_design/form-validation';
import '../new_design/procedure-context';
import '../new_design/select2';
import '../new_design/spinner';
import '../new_design/support';

import '../new_design/champs/carte';
import '../new_design/champs/linked-drop-down-list';
import '../new_design/champs/repetition';

import { toggleCondidentielExplanation } from '../new_design/avis';
import { scrollMessagerie } from '../new_design/messagerie';
import {
  showMotivation,
  motivationCancel,
  showImportJustificatif
} from '../new_design/state-button';
import { toggleChart } from '../new_design/toggle-chart';
import { replaceSemicolonByComma } from '../new_design/avis';

// This is the global application namespace where we expose helpers used from rails views
const DS = {
  fire: (eventName, data) => Rails.fire(document, eventName, data),
  toggleCondidentielExplanation,
  scrollMessagerie,
  showMotivation,
  motivationCancel,
  showImportJustificatif,
  toggleChart,
  replaceSemicolonByComma
};

// Start Rails helpers
Chartkick.addAdapter(Highcharts);
Rails.start();
Turbolinks.start();
ActiveStorage.start();

const loader = new ReactUJS(reactComponents);
loader.start();

// Expose globals
window.DS = window.DS || DS;
window.Chartkick = Chartkick;
