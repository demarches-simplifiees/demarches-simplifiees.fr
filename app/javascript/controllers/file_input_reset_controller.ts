import { ApplicationController } from './application_controller';
import { hide, show } from '@utils';

export class FileInputResetController extends ApplicationController {
  static targets = ['input', 'reset'];

  declare readonly inputTarget: HTMLInputElement;
  declare readonly resetTarget: HTMLElement;

  reset(event: Event) {
    event.preventDefault();
    this.inputTarget.value = '';
    hide(this.resetTarget);
  }

  showResetButton() {
    show(this.resetTarget);
  }
}
