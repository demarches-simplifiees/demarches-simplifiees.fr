import {
  isSelectElement,
  isCheckboxOrRadioInputElement,
  show,
  hide
} from '@utils';

import { ApplicationController } from './application_controller';

export class ChampDropdownController extends ApplicationController {
  connect() {
    this.on('change', (event) => this.onChange(event));
  }

  private onChange(event: Event) {
    const target = event.target as HTMLInputElement;
    if (!target.disabled) {
      if (isSelectElement(target) || isCheckboxOrRadioInputElement(target)) {
        this.toggleOtherInput(target);
      }
    }
  }

  private toggleOtherInput(target: HTMLSelectElement | HTMLInputElement) {
    const parent = target.closest('.editable-champ-drop_down_list');
    const inputGroup = parent?.querySelector<HTMLElement>('.drop_down_other');
    if (inputGroup) {
      const input = inputGroup.querySelector('input');
      if (input) {
        if (target.value == '__other__') {
          show(inputGroup);
          input.disabled = false;
          input.focus();
        } else {
          hide(inputGroup);
          input.disabled = true;
        }
      }
    }
  }
}
