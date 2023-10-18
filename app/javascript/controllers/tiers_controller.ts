import { ApplicationController } from './application_controller';

export class TiersController extends ApplicationController {
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
    this.otherContinueTarget.disabled = !this.iSwearTarget.checked
  }

  nextPage() {
    window.location.pathname = window.location.pathname.replace(/\/commencer_2\//, '/commencer/');
  }
}
