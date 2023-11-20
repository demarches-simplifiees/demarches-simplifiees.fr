import { ApplicationController } from './application_controller';

export class ForTiersController extends ApplicationController {
  static targets = [
    'mandataireFirstName',
    'mandataireLastName',
    'forTiers',
    'mandataireBlock',
    'beneficiaireNotificationBlock',
    'email',
    'notificationMethod',
    'mandataireTitle',
    'beneficiaireTitle',
    'emailInput'
  ];

  declare mandataireFirstNameTarget: HTMLInputElement;
  declare mandataireLastNameTarget: HTMLInputElement;
  declare forTiersTargets: NodeListOf<HTMLInputElement>;
  declare mandataireBlockTarget: HTMLElement;
  declare beneficiaireNotificationBlockTarget: HTMLElement;
  declare notificationMethodTargets: NodeListOf<HTMLInputElement>;
  declare emailTarget: HTMLInputElement;
  declare mandataireTitleTarget: HTMLElement;
  declare beneficiaireTitleTarget: HTMLElement;
  declare emailInput: HTMLInputElement;

  connect() {
    const emailInputElement = this.emailTarget.querySelector('input');
    if (emailInputElement) {
      this.emailInput = emailInputElement;
    }
    this.toggleFieldRequirements();
    this.addAllEventListeners();
  }

  addAllEventListeners() {
    this.forTiersTargets.forEach((radio) => {
      radio.addEventListener('change', () => this.toggleFieldRequirements());
    });
    this.notificationMethodTargets.forEach((radio) => {
      radio.addEventListener('change', () => this.toggleEmailInput());
    });
  }

  toggleFieldRequirements() {
    const forTiersSelected = this.isForTiersSelected();
    this.toggleDisplay(this.mandataireBlockTarget, forTiersSelected);
    this.toggleDisplay(
      this.beneficiaireNotificationBlockTarget,
      forTiersSelected
    );
    this.mandataireFirstNameTarget.required = forTiersSelected;
    this.mandataireLastNameTarget.required = forTiersSelected;
    this.mandataireTitleTarget.classList.toggle('hidden', forTiersSelected);
    this.beneficiaireTitleTarget.classList.toggle('hidden', !forTiersSelected);
    this.notificationMethodTargets.forEach((radio) => {
      radio.required = forTiersSelected;
    });

    this.toggleEmailInput();
  }

  isForTiersSelected() {
    return Array.from(this.forTiersTargets).some(
      (radio) => radio.checked && radio.value === 'true'
    );
  }

  toggleDisplay(element: HTMLElement, shouldDisplay: boolean) {
    element.classList.toggle('hidden', !shouldDisplay);
  }
  toggleEmailInput() {
    const isEmailSelected = this.isEmailSelected();
    const forTiersSelected = this.isForTiersSelected();

    if (this.emailInput) {
      this.emailInput.required = forTiersSelected && isEmailSelected;

      if (!isEmailSelected) {
        this.emailInput.value = '';
      }

      this.toggleDisplay(this.emailTarget, forTiersSelected && isEmailSelected);
    }
  }

  isEmailSelected() {
    return Array.from(this.notificationMethodTargets).some(
      (radio) => radio.value === 'email' && radio.checked
    );
  }
}
