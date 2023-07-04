import { ApplicationController } from './application_controller';
import { disable, enable, show, hide } from '@utils';
import invariant from 'tiny-invariant';

export class BatchOperationController extends ApplicationController {
  static targets = ['menu', 'input'];

  declare readonly menuTargets: HTMLButtonElement[];
  declare readonly hasMenuTarget: boolean;
  declare readonly inputTargets: HTMLInputElement[];

  onCheckOne() {
    this.toggleSubmitButtonWhenNeeded();
    deleteSelection();
  }

  onCheckAll(event: Event) {
    const target = event.target as HTMLInputElement;

    this.inputTargets.forEach((e) => (e.checked = target.checked));
    this.toggleSubmitButtonWhenNeeded();

    const pagination = document.querySelector('tfoot .fr-pagination');
    if (pagination) {
      displayNotice(this.inputTargets);
    }

    // add focus on button for a11y
    const button = document.getElementById('js_select_more');
    if (button) {
      button.focus();
    }
  }

  onSelectMore(event: {
    preventDefault: () => void;
    target: HTMLInputElement;
  }) {
    event.preventDefault();

    const target = event.target as HTMLInputElement;
    const dossierIds = target.getAttribute('data-dossiers');

    const hidden_input_multiple_ids = document.querySelector<HTMLInputElement>(
      '#input_multiple_ids_batch_operation'
    );
    if (hidden_input_multiple_ids) {
      hidden_input_multiple_ids.value = dossierIds || '';
    }

    hide(document.querySelector('#not_selected'));
    show(document.querySelector('#selected'));

    // add focus on button for a11y
    const button = document.getElementById('js_delete_selection');
    if (button) {
      button.focus();
    }
  }

  onDeleteSelection(event: { preventDefault: () => void }) {
    event.preventDefault();
    emptyCheckboxes();
    deleteSelection();
    this.toggleSubmitButtonWhenNeeded();
  }

  toggleSubmitButtonWhenNeeded() {
    const buttons = [
      ...this.element.querySelectorAll<HTMLButtonElement>('[data-operation]')
    ];
    const checked = this.inputTargets.filter((input) => input.checked);
    if (checked.length) {
      const available = buttons.filter((button) => {
        const operation = button.dataset.operation;
        invariant(operation, 'data-operation is required');
        const available = checked.every(isInputForOperation(operation));
        switchButton(button, available);
        return available;
      });

      if (this.hasMenuTarget) {
        if (available.length) {
          this.menuTargets.forEach((e) => enable(e));
        } else {
          this.menuTargets.forEach((e) => disable(e));
        }
      }
    } else {
      if (this.hasMenuTarget) {
        this.menuTargets.forEach((e) => disable(e));
      }
      buttons.forEach((button) => switchButton(button, false));
    }
  }
}

function isInputForOperation(operation: string) {
  return (input: HTMLInputElement) =>
    (input.dataset.operations?.split(',') ?? []).includes(operation);
}

function switchButton(button: HTMLButtonElement, flag: boolean) {
  if (flag) {
    enable(button);
    button.querySelectorAll('button').forEach((button) => enable(button));
  } else {
    disable(button);
    button.querySelectorAll('button').forEach((button) => disable(button));
  }
}

function displayNotice(inputs: HTMLInputElement[]) {
  const checkbox_all = document.querySelector<HTMLInputElement>(
    '#checkbox_all_batch_operation'
  );
  if (checkbox_all) {
    if (checkbox_all.checked) {
      show(document.querySelector('#js_batch_select_more'));
      hide(document.querySelector('#selected'));
      show(document.querySelector('#not_selected'));
    } else {
      hide(document.querySelector('#js_batch_select_more'));
      deleteSelection();
    }
  }

  const dynamic_number = document.querySelector('#dynamic_number');

  if (dynamic_number) {
    dynamic_number.textContent = inputs.length.toString();
  }
}

function deleteSelection() {
  const hidden_input_multiple_ids = document.querySelector<HTMLInputElement>(
    '#input_multiple_ids_batch_operation'
  );

  if (hidden_input_multiple_ids) {
    hidden_input_multiple_ids.value = '';
  }

  hide(document.querySelector('#js_batch_select_more'));
}

function emptyCheckboxes() {
  const inputs = document.querySelectorAll<HTMLInputElement>(
    'div[data-controller="batch-operation"] input[type=checkbox]'
  );
  inputs.forEach((e) => (e.checked = false));
}
