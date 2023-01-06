import { ApplicationController } from './application_controller';
import { show, hide } from '@utils';
const AUTOSUBMIT_DEBOUNCE_DELAY = 5000;

export class AutosubmitController extends ApplicationController {
  static targets = ['form', 'spinner'];

  declare readonly formTarget: HTMLFormElement;
  declare readonly spinnerTarget: HTMLElement;
  declare readonly hasSpinnerTarget: boolean;

  submit() {
    this.formTarget.requestSubmit();
  }

  debouncedSubmit() {
    this.debounce(this.submit, AUTOSUBMIT_DEBOUNCE_DELAY);
  }

  connect() {
    this.onGlobal('turbo:submit-start', () => {
      if (this.hasSpinnerTarget) {
        show(this.spinnerTarget);
      }
    });
    this.onGlobal('turbo:submit-end', () => {
      if (this.hasSpinnerTarget) {
        hide(this.spinnerTarget);
      }
    });
  }
}
