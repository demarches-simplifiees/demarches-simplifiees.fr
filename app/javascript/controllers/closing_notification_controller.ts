import { ApplicationController } from './application_controller';
import { hide, show } from '@utils';

export class ClosingNotificationController extends ApplicationController {
  static targets = [
    'brouillonToggle',
    'emailContentBrouillon',
    'enCoursToggle',
    'emailContentEnCours',
    'submit'
  ];

  declare readonly brouillonToggleTarget: HTMLInputElement;
  declare readonly hasBrouillonToggleTarget: boolean;
  declare readonly enCoursToggleTarget: HTMLInputElement;
  declare readonly hasEnCoursToggleTarget: boolean;
  declare readonly emailContentBrouillonTarget: HTMLElement;
  declare readonly emailContentEnCoursTarget: HTMLElement;
  declare readonly submitTarget: HTMLButtonElement;

  connect() {
    this.displayBrouillonInput();
    this.displayEnCoursInput();
    this.on('change', () => this.onChange());
  }

  onChange() {
    this.displayBrouillonInput();
    this.displayEnCoursInput();
  }

  displayBrouillonInput() {
    if (this.hasBrouillonToggleTarget) {
      const brouillonToggleElement = this
        .brouillonToggleTarget as HTMLInputElement;

      const emailContentBrouillonElement = this
        .emailContentBrouillonTarget as HTMLElement;

      if (emailContentBrouillonElement) {
        if (brouillonToggleElement.checked) {
          show(emailContentBrouillonElement);
        } else {
          hide(emailContentBrouillonElement);
        }
      }
    }
  }

  displayEnCoursInput() {
    if (this.hasEnCoursToggleTarget) {
      const enCoursToggleElement = this.enCoursToggleTarget as HTMLInputElement;

      const emailContentEnCoursElement = this
        .emailContentEnCoursTarget as HTMLElement;

      if (emailContentEnCoursElement) {
        if (enCoursToggleElement.checked) {
          show(this.emailContentEnCoursTarget);
        } else {
          hide(this.emailContentEnCoursTarget);
        }
      }
    }
  }

  enableSubmitOnClick() {
    if (
      this.element.querySelectorAll('input[type="checkbox"]:checked').length > 0
    ) {
      this.submitTarget.disabled = false;
    } else {
      this.submitTarget.disabled = true;
    }
  }
}
