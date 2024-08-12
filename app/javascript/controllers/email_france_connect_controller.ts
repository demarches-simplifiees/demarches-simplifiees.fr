import { ApplicationController } from './application_controller';

export class EmailFranceConnectController extends ApplicationController {
  static targets = ['useFranceConnectEmail', 'emailField'];

  emailFieldTarget!: HTMLElement;
  useFranceConnectEmailTargets!: HTMLInputElement[];

  connect() {
    this.triggerEmailField();
  }

  triggerEmailField() {
    const checkedTarget = this.useFranceConnectEmailTargets.find(
      (target) => target.checked
    );

    const inputElement = this.emailFieldTarget.querySelector(
      'input[type="email"]'
    ) as HTMLInputElement;

    if (checkedTarget && checkedTarget.value === 'false') {
      this.emailFieldTarget.classList.remove('fr-hidden');
      inputElement.setAttribute('required', '');
    } else {
      this.emailFieldTarget.classList.add('fr-hidden');
      inputElement.removeAttribute('required');
      inputElement.value = '';
    }
  }
}
