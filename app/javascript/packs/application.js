import '../shared/polyfills';
import Rails from '@rails/ujs';
import * as ActiveStorage from '@rails/activestorage';
import 'whatwg-fetch'; // window.fetch polyfill

import '../shared/page-update-event';
import '../shared/activestorage/ujs';
import '../shared/remote-poller';
import '../shared/safari-11-file-xhr-workaround';
import '../shared/remote-input';
import '../shared/franceconnect';
import '../shared/toggle-target';
import '../shared/ujs-error-handling';

import '../new_design/chartkick';
import '../new_design/dropdown';
import '../new_design/form-validation';
import '../new_design/procedure-context';
import '../new_design/procedure-form';
import '../new_design/spinner';
import '../new_design/support';
import '../new_design/messagerie';
import '../new_design/dossiers/auto-save';
import '../new_design/dossiers/auto-upload';

import '../new_design/champs/carte';
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

import {
  registerReactComponents,
  Loadable
} from '../shared/register-react-components';

registerReactComponents({
  Chartkick: Loadable(() => import('../components/Chartkick')),
  ComboAdresseSearch: Loadable(() =>
    import('../components/ComboAdresseSearch')
  ),
  ComboAnnuaireEducationSearch: Loadable(() =>
    import('../components/ComboAnnuaireEducationSearch')
  ),
  ComboCommunesSearch: Loadable(() =>
    import('../components/ComboCommunesSearch')
  ),
  ComboDepartementsSearch: Loadable(() =>
    import('../components/ComboDepartementsSearch')
  ),
  ComboMultipleDropdownList: Loadable(() =>
    import('../components/ComboMultipleDropdownList')
  ),
  ComboPaysSearch: Loadable(() => import('../components/ComboPaysSearch')),
  ComboRegionsSearch: Loadable(() =>
    import('../components/ComboRegionsSearch')
  ),
  MapEditor: Loadable(() => import('../components/MapEditor')),
  MapReader: Loadable(() => import('../components/MapReader')),
  Trix: Loadable(() => import('../components/Trix')),
  TypesDeChampEditor: Loadable(() => import('../components/TypesDeChampEditor'))
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

// Expose globals
window.DS = window.DS || DS;
