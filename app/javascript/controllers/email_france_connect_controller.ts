import { ApplicationController } from './application_controller';

export class EmailFranceConnectController extends ApplicationController {
  static targets = ['useFranceConnectEmail', 'emailField'];

  emailFieldTarget!: HTMLElement;
  useFranceConnectEmailTargets!: HTMLInputElement[];

  connect() {
    this.toggleEmailField();
  }

  toggleEmailField() {
    const checkedTarget = this.useFranceConnectEmailTargets.find(
      (target) => target.checked
    );

    if (checkedTarget && checkedTarget.value === 'false') {
      this.emailFieldTarget.classList.remove('hidden');
    } else {
      this.emailFieldTarget.classList.add('hidden');
    }
  }
}
