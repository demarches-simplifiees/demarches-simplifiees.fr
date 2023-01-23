import { ApplicationController } from './application_controller';
import { disable, enable, show, hide } from '@utils';
import invariant from 'tiny-invariant';

export class BatchOperationController extends ApplicationController {
  static targets = ['menu', 'input'];

  declare readonly menuTarget: HTMLButtonElement;
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

    const pagination = document.querySelector('.pagination')
    if (pagination) {
      displayNotice(this.inputTargets);
    }
  }

  onSelectMore(event) {
    event.preventDefault();

    const target = event.target as HTMLInputElement;
    const dossierIds = target.getAttribute('data-dossiers');
    const hidden_checkbox_multiple_ids = document.querySelector('#checkbox_multiple_batch_operation');
    hidden_checkbox_multiple_ids.value = dossierIds;
    hide(document.querySelector('#not_selected'));
    show(document.querySelector('#selected'));
  }

  onDeleteSelection(event) {
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
          enable(this.menuTarget);
        } else {
          disable(this.menuTarget);
        }
      }
    } else {
      if (this.hasMenuTarget) {
        disable(this.menuTarget);
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

function displayNotice(inputs) {
  if (document.querySelector('#checkbox_all_batch_operation').checked) {
    show(document.querySelector('.fr-notice'));
    hide(document.querySelector('#selected'));
    show(document.querySelector('#not_selected'));
  } else {
    hide(document.querySelector('.fr-notice'));
    deleteSelection();
  };

  document.querySelector('#dynamic_number').textContent = (inputs.length - 1);
}

function deleteSelection() {
  const hidden_checkbox_multiple_ids = document.querySelector('#checkbox_multiple_batch_operation');
  hidden_checkbox_multiple_ids.value = "";

  hide(document.querySelector('.fr-notice'));
}

function emptyCheckboxes() {
  const inputs = document.querySelectorAll('div[data-controller="batch-operation"] input[type=checkbox]')
  inputs.forEach((e) => (e.checked = false));
}
