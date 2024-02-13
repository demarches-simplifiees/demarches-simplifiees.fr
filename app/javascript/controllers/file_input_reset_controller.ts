import { ApplicationController } from './application_controller';
import { hide, show } from '@utils';

export class FileInputResetController extends ApplicationController {
  static targets = ['reset'];

  declare readonly resetTarget: HTMLElement;

  connect() {
    this.on('change', (event) => {
      if (event.target == this.fileInput) {
        this.showResetButton();
      }
    });
  }

  reset(event: Event) {
    event.preventDefault();
    this.fileInput.value = '';
    hide(this.resetTarget);
  }

  showResetButton() {
    show(this.resetTarget);
  }

  private get fileInput() {
    const inputs =
      this.element.querySelectorAll<HTMLInputElement>('input[type="file"]');
    if (inputs.length == 0) {
      throw new Error('No file input found');
    } else if (inputs.length > 1) {
      throw new Error('Multiple file inputs found');
    }
    return inputs[0];
  }
}
