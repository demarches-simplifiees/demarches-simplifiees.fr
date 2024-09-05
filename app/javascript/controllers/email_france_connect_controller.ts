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
      this.emailFieldTarget.classList.remove('hidden');
      this.emailFieldTarget.setAttribute('aria-hidden', 'false');
      inputElement.setAttribute('required', '');
    } else {
      this.emailFieldTarget.classList.add('hidden');
      this.emailFieldTarget.setAttribute('aria-hidden', 'true');
      inputElement.removeAttribute('required');
      inputElement.value = '';
    }
  }
}
