import { show, hide } from '@utils';
import { session as TurboSession } from '@hotwired/turbo';

import { ApplicationController } from './application_controller';

export class TurboController extends ApplicationController {
  static targets = ['spinner'];

  declare readonly spinnerTarget: HTMLElement;
  declare readonly hasSpinnerTarget: boolean;

  #submitting = true;

  connect() {
    this.onGlobal('turbo:submit-start', () => this.startSpinner());
    this.onGlobal('turbo:submit-end', () => this.stopSpinner());
    this.onGlobal('turbo:fetch-request-error', () => this.stopSpinner());

    // prevent scroll on turbo form submits
    this.onGlobal('turbo:render', () => this.preventScrollIfNeeded());
  }

  startSpinner() {
    this.#submitting = true;
    if (this.hasSpinnerTarget) {
      show(this.spinnerTarget);
    }
  }

  stopSpinner() {
    this.#submitting = false;
    if (this.hasSpinnerTarget) {
      hide(this.spinnerTarget);
    }
  }

  preventScrollIfNeeded() {
    if (this.#submitting && TurboSession.navigator.currentVisit) {
      TurboSession.navigator.currentVisit.scrolled = true;
    }
  }
}
