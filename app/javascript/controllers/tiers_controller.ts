import { ApplicationController } from './application_controller';

export class TiersController extends ApplicationController {
   static values = { procedureid: Number }

  static targets = ['other', 'selfContinue', 'iSwear', 'otherContinue'];

  declare otherTarget: HTMLElement;
  declare selfContinueTarget: HTMLElement;
  declare otherContinueTarget: HTMLElement;
  declare iSwearTarget: HTMLElement;

  showTiers() {
    this.otherTarget.style.display = 'block';
    this.selfContinueTarget.style.display = 'none';
  }

  hideTiers() {
    this.otherTarget.style.display = 'none';
    this.selfContinueTarget.style.display = 'block';
  }

  toggleOtherContinue() {
    if (this.iSwearTarget.checked) {
      this.otherContinueTarget.removeAttribute('disabled')
    } else {
      this.otherContinueTarget.setAttribute("disabled", "disabled");;
    }
  }

  nextPage() {
    window.location = `http://localhost:3000/dossiers/new?procedure_id=${this.procedureidValue}`;
  }
}
