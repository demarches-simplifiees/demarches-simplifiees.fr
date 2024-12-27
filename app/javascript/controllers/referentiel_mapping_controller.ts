import { ApplicationController } from './application_controller';

export class ReferentielMappingController extends ApplicationController {
  static targets = ['input'];

  declare readonly checkboxTarget: HTMLInputElement;
  declare readonly inputTarget: HTMLInputElement;

  connect() {
    console.log('connected', this.checkboxTarget, this.inputTarget);
  }

  onCheckboxChange(event:Event) {
    const checkbox = event.currentTarget as HTMLInputElement;

    this.inputTarget.disabled = checkbox.checked;
  }
}