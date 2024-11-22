import { ApplicationController } from './application_controller';

export class EmailFranceConnectController extends ApplicationController {
  static targets = ['useFranceConnectEmail', 'emailField', 'submit', 'emailInput'];

  emailFieldTarget!: HTMLElement;
  useFranceConnectEmailTargets!: HTMLInputElement[];
  submitTarget!: HTMLButtonElement;
  emailInputTarget!: HTMLInputElement;

  triggerEmailField() {
    if (this.useFCEmail()) {
      this.emailFieldTarget.classList.add('hidden');
      this.emailFieldTarget.setAttribute('aria-hidden', 'true');

      this.emailInputTarget.removeAttribute('required');
      this.emailInputTarget.value = '';
    } else {
      this.emailFieldTarget.classList.remove('hidden');
      this.emailFieldTarget.setAttribute('aria-hidden', 'false');

      this.emailInputTarget.setAttribute('required', '');
    }
  }

  triggerSubmitDisabled() {
    if (this.useFCEmail() || this.isEmailInputFilled()) {
      this.submitTarget.disabled = false;
    } else {
      this.submitTarget.disabled = true;
    }
  }

  useFCEmail() {
    return this.useFranceConnectEmailTargets.find(
      (target) => target.checked
    )?.value === 'true' || false;
  }

  isEmailInputFilled() {
    return this.emailInputTarget.value.length > 0;
  }
}
