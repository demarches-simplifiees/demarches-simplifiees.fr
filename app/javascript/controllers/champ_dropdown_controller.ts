import {
  isSelectElement,
  isCheckboxOrRadioInputElement,
  show,
  hide,
  enable,
  disable
} from '@utils';
import { z } from 'zod';

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
        this.toggleLinkedSelect(target);
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
        } else {
          hide(inputGroup);
          input.disabled = true;
        }
      }
    }
  }

  private toggleLinkedSelect(target: HTMLSelectElement | HTMLInputElement) {
    const secondaryOptions = target.dataset.secondaryOptions;
    if (isSelectElement(target) && secondaryOptions) {
      const parent = target.closest('.editable-champ-linked_drop_down_list');
      const secondary = parent?.querySelector<HTMLSelectElement>(
        'select[data-secondary]'
      );
      if (secondary) {
        const options = parseOptions(secondaryOptions);
        this.setSecondaryOptions(secondary, options[target.value]);
      }
    }
  }

  private setSecondaryOptions(
    secondarySelectElement: HTMLSelectElement,
    options: string[]
  ) {
    const wrapper = secondarySelectElement.closest('.secondary');
    const hidden = wrapper?.nextElementSibling as HTMLInputElement | null;

    secondarySelectElement.innerHTML = '';

    if (options.length) {
      disable(hidden);

      if (secondarySelectElement.required) {
        secondarySelectElement.appendChild(makeOption(''));
      }
      for (const option of options) {
        secondarySelectElement.appendChild(makeOption(option));
      }

      secondarySelectElement.selectedIndex = 0;
      enable(secondarySelectElement);
      show(wrapper);
    } else {
      hide(wrapper);
      disable(secondarySelectElement);
      enable(hidden);
    }
  }
}

const SecondaryOptions = z.record(z.string().array());

function parseOptions(options: string) {
  return SecondaryOptions.parse(JSON.parse(options));
}

function makeOption(option: string) {
  const element = document.createElement('option');
  element.textContent = option;
  element.value = option;
  return element;
}
