import { ApplicationController } from './application_controller';

export class ReferentielNewFormController extends ApplicationController {
  static targets = ['input'];

  declare readonly inputTarget: HTMLInputElement;

  changeHeaderValue(event: Event) {
    event.preventDefault();
    this.inputTarget.value = '';
    this.inputTarget.disabled = false;
    this.inputTarget.focus();
  }
}
