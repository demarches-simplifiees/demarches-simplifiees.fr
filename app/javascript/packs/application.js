import '../shared/polyfills';
import Rails from '@rails/ujs';
import * as ActiveStorage from '@rails/activestorage';
import 'whatwg-fetch'; // window.fetch polyfill
import { Application } from '@hotwired/stimulus';
import * as Turbo from '@hotwired/turbo';

import '../shared/activestorage/ujs';
import '../shared/remote-poller';
import '../shared/safari-11-file-xhr-workaround';
import '../shared/franceconnect';
import '../shared/toggle-target';
import '../shared/ujs-error-handling';

import {
  ReactController,
  registerComponents
} from '../controllers/react_controller';
import { TurboEventController } from '../controllers/turbo_event_controller';
import { GeoAreaController } from '../controllers/geo_area_controller';
import { TurboInputController } from '../controllers/turbo_input_controller';

import '../new_design/dropdown';
import '../new_design/form-validation';
import '../new_design/procedure-context';
import '../new_design/procedure-form';
import '../new_design/spinner';
import '../new_design/support';
import '../new_design/messagerie';
import '../new_design/dossiers/auto-save';
import '../new_design/dossiers/auto-upload';

import '../new_design/champs/linked-drop-down-list';
import '../new_design/champs/repetition';
import '../new_design/champs/drop-down-list';

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
import {
  showFusion,
  showNewAccount,
  showNewAccountPasswordConfirmation
} from '../new_design/fc-fusion';

registerComponents({
  Chartkick: () => import('../components/Chartkick'),
  ComboAdresseSearch: () => import('../components/ComboAdresseSearch'),
  ComboAnnuaireEducationSearch: () =>
    import('../components/ComboAnnuaireEducationSearch'),
  ComboCommunesSearch: () => import('../components/ComboCommunesSearch'),
  ComboDepartementsSearch: () =>
    import('../components/ComboDepartementsSearch'),
  ComboMultipleDropdownList: () =>
    import('../components/ComboMultipleDropdownList'),
  ComboMultiple: () => import('../components/ComboMultiple'),
  ComboPaysSearch: () => import('../components/ComboPaysSearch'),
  ComboRegionsSearch: () => import('../components/ComboRegionsSearch'),
  MapEditor: () => import('../components/MapEditor'),
  MapReader: () => import('../components/MapReader'),
  Trix: () => import('../components/Trix'),
  TypesDeChampEditor: () => import('../components/TypesDeChampEditor')
});

// This is the global application namespace where we expose helpers used from rails views
const DS = {
  fire: (eventName, data) => Rails.fire(document, eventName, data),
  toggleCondidentielExplanation,
  showMotivation,
  motivationCancel,
  showImportJustificatif,
  showFusion,
  showNewAccount,
  showNewAccountPasswordConfirmation,
  replaceSemicolonByComma,
  acceptEmailSuggestion,
  discardEmailSuggestionBox
};

// Start Rails helpers
Rails.start();
ActiveStorage.start();
Turbo.session.drive = false;

const Stimulus = Application.start();
Stimulus.register('react', ReactController);
Stimulus.register('turbo-event', TurboEventController);
Stimulus.register('geo-area', GeoAreaController);
Stimulus.register('turbo-input', TurboInputController);

// Expose globals
window.DS = window.DS || DS;
