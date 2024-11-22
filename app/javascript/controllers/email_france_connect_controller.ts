import { ApplicationController } from './application_controller';

export class EmailFranceConnectController extends ApplicationController {
  static targets = [
    'useFranceConnectEmail',
    'emailField',
    'submit',
    'emailInput',
    'form'
  ];

  emailFieldTarget!: HTMLElement;
  useFranceConnectEmailTargets!: HTMLInputElement[];
  submitTarget!: HTMLButtonElement;
  emailInputTarget!: HTMLInputElement;
  formTarget!: HTMLFormElement;

  fcEmailPathValue!: string;
  customEmailPathValue!: string;

  static values = {
    fcEmailPath: String,
    customEmailPath: String
  };

  triggerEmailField() {
    if (this.useFCEmail()) {
      this.emailFieldTarget.classList.add('hidden');
      this.emailFieldTarget.setAttribute('aria-hidden', 'true');

      this.emailInputTarget.removeAttribute('required');
      this.emailInputTarget.value = '';

      this.formTarget.action = this.fcEmailPathValue;
    } else {
      this.emailFieldTarget.classList.remove('hidden');
      this.emailFieldTarget.setAttribute('aria-hidden', 'false');

      this.emailInputTarget.setAttribute('required', '');

      this.formTarget.action = this.customEmailPathValue;
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
    return (
      this.useFranceConnectEmailTargets.find((target) => target.checked)
        ?.value === 'true' || false
    );
  }

  isEmailInputFilled() {
    return this.emailInputTarget.value.length > 0;
  }
}
