import { toggle } from '@utils';
import { ApplicationController } from './application_controller';

function onVisibleEnableInputs(element: HTMLInputElement) {
  element.disabled = false;
  element.required = true;
}

function onHiddenDisableInputs(element: HTMLInputElement) {
  element.disabled = true;
  element.required = false;
}

export class ForTiersController extends ApplicationController {
  static targets = ['emailContainer', 'emailInput', 'notificationMethod'];

  declare notificationMethodTargets: NodeListOf<HTMLInputElement>;
  declare emailContainerTarget: HTMLElement;
  declare emailInputTarget: HTMLInputElement;

  toggleEmailInput() {
    const isEmailSelected = this.isEmailSelected();

    toggle(this.emailContainerTarget, isEmailSelected);

    if (isEmailSelected) {
      onVisibleEnableInputs(this.emailInputTarget);
    } else {
      onHiddenDisableInputs(this.emailInputTarget);
    }
  }

  isEmailSelected() {
    return Array.from(this.notificationMethodTargets).some(
      (radio) => radio.value === 'email' && radio.checked
    );
  }
}
