import invariant from 'tiny-invariant';
import { isInputElement, isElement } from '@coldwired/utils';

import { Hint } from '../shared/combobox';
import { ComboboxUI } from '../shared/combobox-ui';
import { ApplicationController } from './application_controller';

export class ComboboxController extends ApplicationController {
  #combobox?: ComboboxUI;

  connect() {
    const { input, selectedValueInput, valueSlots, list, item, hint } =
      this.getElements();
    const hints = JSON.parse(list.dataset.hints ?? '{}') as Record<
      string,
      string
    >;
    this.#combobox = new ComboboxUI({
      input,
      selectedValueInput,
      valueSlots,
      list,
      item,
      hint,
      allowsCustomValue: this.element.hasAttribute('data-allows-custom-value'),
      limit: this.element.hasAttribute('data-limit')
        ? Number(this.element.getAttribute('data-limit'))
        : undefined,
      getHintText: (hint) => getHintText(hints, hint)
    });
    this.#combobox.init();
  }

  disconnect() {
    this.#combobox?.destroy();
  }

  private getElements() {
    const input =
      this.element.querySelector<HTMLInputElement>('input[type="text"]');
    const selectedValueInput = this.element.querySelector<HTMLInputElement>(
      'input[type="hidden"]'
    );
    const valueSlots = this.element.querySelectorAll<HTMLInputElement>(
      'input[type="hidden"][data-value-slot]'
    );
    const list = this.element.querySelector<HTMLUListElement>('[role=listbox]');
    const item = this.element.querySelector<HTMLTemplateElement>('template');
    const hint =
      this.element.querySelector<HTMLElement>('[aria-live]') ?? undefined;

    invariant(
      isInputElement(input),
      'ComboboxController requires a input element'
    );
    invariant(
      isInputElement(selectedValueInput),
      'ComboboxController requires a hidden input element'
    );
    invariant(
      isElement(list),
      'ComboboxController requires a [role=listbox] element'
    );
    invariant(
      isElement(item),
      'ComboboxController requires a template element'
    );

    return { input, selectedValueInput, valueSlots, list, item, hint };
  }
}

function getHintText(hints: Record<string, string>, hint: Hint): string {
  const slot = hints[getSlotName(hint)];
  switch (hint.type) {
    case 'empty':
      return slot;
    case 'selected':
      return slot.replace('{label}', hint.label ?? '');
    default:
      return slot
        .replace('{count}', String(hint.count))
        .replace('{label}', hint.label ?? '');
  }
}

function getSlotName(hint: Hint): string {
  switch (hint.type) {
    case 'empty':
      return 'empty';
    case 'selected':
      return 'selected';
    default:
      if (hint.count == 1) {
        return hint.label ? 'oneWithLabel' : 'one';
      }
      return hint.label ? 'manyWithLabel' : 'many';
  }
}
