import '../shared/polyfills';
import Rails from '@rails/ujs';
import * as ActiveStorage from '@rails/activestorage';
import 'whatwg-fetch'; // window.fetch polyfill
import ReactRailsUJS from 'react_ujs';

import '../shared/page-update-event';
import '../shared/activestorage/ujs';
import '../shared/remote-poller';
import '../shared/safari-11-file-xhr-workaround';
import '../shared/autocomplete';
import '../shared/remote-input';
import '../shared/franceconnect';
import '../shared/toggle-target';

import '../new_design/chartkick';
import '../new_design/dropdown';
import '../new_design/form-validation';
import '../new_design/procedure-context';
import '../new_design/procedure-form';
import '../new_design/select2';
import '../new_design/spinner';
import '../new_design/support';
import '../new_design/dossiers/auto-save';
import '../new_design/dossiers/auto-upload';

import '../new_design/champs/te_fenua';
import '../new_design/champs/numero_dn';

import '../new_design/champs/carte';
import '../new_design/champs/linked-drop-down-list';
import '../new_design/champs/repetition';

import {
  toggleCondidentielExplanation,
  replaceSemicolonByComma
} from '../new_design/avis';
import {
  showMotivation,
  motivationCancel,
  showImportJustificatif
} from '../new_design/state-button';
import {
  acceptEmailSuggestion,
  discardEmailSuggestionBox
} from '../new_design/user-sign_up';

// This is the global application namespace where we expose helpers used from rails views
const DS = {
  fire: (eventName, data) => Rails.fire(document, eventName, data),
  toggleCondidentielExplanation,
  showMotivation,
  motivationCancel,
  showImportJustificatif,
  replaceSemicolonByComma,
  acceptEmailSuggestion,
  discardEmailSuggestionBox
};

// Start Rails helpers
Rails.start();
ActiveStorage.start();

// Expose globals
window.DS = window.DS || DS;

// eslint-disable-next-line no-undef, react-hooks/rules-of-hooks
ReactRailsUJS.useContext(require.context('loaders', true));
addEventListener('ds:page:update', ReactRailsUJS.handleMount);
