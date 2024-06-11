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

  declare dialogTarget: HTMLElement;

  connect() {
    setTimeout(() => window.dsfr(this.dialogTarget).modal.disclose(), 100);
  }
}
