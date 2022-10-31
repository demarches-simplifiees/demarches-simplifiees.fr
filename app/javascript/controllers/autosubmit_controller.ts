import { ApplicationController } from './application_controller';
import { toggle } from '@utils';

export class AutosubmitController extends ApplicationController {
  static targets = ['form', 'spinner'];

  declare readonly formTarget: HTMLFormElement;
  declare readonly spinnerTarget: HTMLElement;

  submit() {
    this.formTarget.requestSubmit();
  }
  connect() {
    this.onGlobal('turbo:submit-start', () => {
      toggle(this.spinnerTarget);
    });
  }
}
