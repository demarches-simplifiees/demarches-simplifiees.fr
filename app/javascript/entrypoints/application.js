import Rails from '@rails/ujs';
import * as ActiveStorage from '@rails/activestorage';
import * as Turbo from '@hotwired/turbo';
import { Application } from '@hotwired/stimulus';

import '../shared/activestorage/ujs';
import '../shared/remote-poller';
import '../shared/safari-11-file-xhr-workaround';
import '../shared/toggle-target';
import '../shared/ujs-error-handling';

import { registerControllers } from '../shared/stimulus-loader';

import '../new_design/form-validation';
import '../new_design/procedure-context';
import '../new_design/procedure-form';
import '../new_design/spinner';
import '../new_design/support';

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

const application = Application.start();
registerControllers(application);

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
ActiveStorage.start();
if (!window._rails_loaded) {
  Rails.start();
}
Turbo.session.drive = false;

// Expose globals
window.DS = window.DS || DS;

import('../shared/track/matomo');
import('../shared/track/sentry');

// import "../../../node_modules/@gouvfr/dsfr/dist/dsfr.min.css";

import '../../../node_modules/@gouvfr/dsfr/dist/core/core.css';
import '../../../node_modules/@gouvfr/dsfr/dist/component/button/button.css';
import '../../../node_modules/@gouvfr/dsfr/dist/component/alert/alert.css';
