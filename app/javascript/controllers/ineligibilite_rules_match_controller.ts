import { ApplicationController } from './application_controller';
declare interface modal {
  disclose: () => void;
}
declare interface dsfr {
  modal: modal;
}
declare const window: Window &
  typeof globalThis & { dsfr: (elem: HTMLElement) => dsfr };

export class InvalidIneligibiliteRulesController extends ApplicationController {
  static targets = ['dialog'];
  static values = {
    open: String
  };

  declare dialogTarget: HTMLElement;
  declare openValue: 'true' | 'false';

  connect() {
    if (this.openValue == 'true') {
      this.openModal();
    }
  }

  openValueChanged() {
    if (this.openValue == 'true') {
      this.openModal();
    }
  }

  private openModal() {
    setTimeout(() => {
      window.dsfr(this.dialogTarget).modal.disclose();
    }, 100);
  }
}
