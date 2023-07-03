import { ApplicationController } from './application_controller';
import { disable, enable } from '@utils';

export class BatchOperationController extends ApplicationController {
  static targets = ['input'];

  declare readonly inputTargets: HTMLInputElement[];

  onCheckOne() {
    this.toggleSubmitButtonWhenNeeded();
  }

  onCheckAll(event: Event) {
    const target = event.target as HTMLInputElement;

    this.inputTargets.forEach((e) => (e.checked = target.checked));
    this.toggleSubmitButtonWhenNeeded();
  }

  toggleSubmitButtonWhenNeeded() {
    const available = this.inputTargets.some((e) => e.checked);
    const buttons = this.element.querySelectorAll<HTMLButtonElement>(
      '.batch-operation button'
    );
    for (const button of buttons) {
      if (available) {
        enable(button);
      } else {
        disable(button);
      }
    }
  }
}
