import { ApplicationController } from './application_controller';

export class ReferentielNewFormController extends ApplicationController {
  static targets = ['header', 'value'];

  declare readonly valueTarget: HTMLInputElement;
  declare readonly headerTarget: HTMLInputElement;

  changeHeaderValue(event: Event) {
    event.preventDefault();
    this.valueTarget.value = '';
    this.valueTarget.disabled = this.headerTarget.disabled = false;
    this.valueTarget.focus();
  }
}
