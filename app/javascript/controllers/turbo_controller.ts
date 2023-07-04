import { show, hide } from '@utils';

import { ApplicationController } from './application_controller';

export class TurboController extends ApplicationController {
  static targets = ['spinner'];

  declare readonly spinnerTarget: HTMLElement;
  declare readonly hasSpinnerTarget: boolean;

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
