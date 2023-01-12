import { ApplicationController } from './application_controller';
import { disable, enable } from '@utils';
import invariant from 'tiny-invariant';

export class BatchOperationController extends ApplicationController {
  static targets = ['menu', 'input'];

  declare readonly menuTarget: HTMLButtonElement;
  declare readonly hasMenuTarget: boolean;
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
