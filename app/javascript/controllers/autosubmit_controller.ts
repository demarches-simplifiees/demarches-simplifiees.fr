import { ApplicationController } from './application_controller';
import { toggle } from '@utils';
const AUTOSUBMIT_DEBOUNCE_DELAY = 5000;

export class AutosubmitController extends ApplicationController {
  static targets = ['form', 'spinner'];

  declare readonly formTarget: HTMLFormElement;
  declare readonly spinnerTarget: HTMLElement;

  submit() {
    this.formTarget.requestSubmit();
  }

  debouncedSubmit() {
    this.debounce(this.submit, AUTOSUBMIT_DEBOUNCE_DELAY);
  }

  connect() {
    this.onGlobal('turbo:submit-start', () => {
      toggle(this.spinnerTarget);
    });
  }
}
