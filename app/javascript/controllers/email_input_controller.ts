import { suggest } from 'email-butler';
import { show, hide } from '@utils';
import { ApplicationController } from './application_controller';

export class EmailInputController extends ApplicationController {
  static targets = ['ariaRegion', 'suggestion', 'input'];

  declare readonly ariaRegionTarget: HTMLElement;
  declare readonly suggestionTarget: HTMLElement;
  declare readonly inputTarget: HTMLInputElement;

  checkEmail() {
    const email = this.inputTarget.value;
    if (email.toLowerCase().endsWith('@gmail.pf')) {
      const address = email.substring(0, email.indexOf('@')) + '@gmail.com';
      this.suggestionTarget.innerHTML = address;
      show(this.ariaRegionTarget);
      this.ariaRegionTarget.setAttribute('aria-live', 'assertive');
    } else if (email.toLowerCase().endsWith('.pf')) {
      this.discard();
    } else {
      const suggestion = suggest(email);
      if (suggestion && suggestion.full) {
        this.suggestionTarget.innerHTML = suggestion.full;
        show(this.ariaRegionTarget);
        this.ariaRegionTarget.setAttribute('aria-live', 'assertive');
      }
    }
  }

  accept() {
    this.ariaRegionTarget.setAttribute('aria-live', 'off');
    hide(this.ariaRegionTarget);
    this.inputTarget.value = this.suggestionTarget.innerHTML;
    this.suggestionTarget.innerHTML = '';
  }

  discard() {
    this.ariaRegionTarget.setAttribute('aria-live', 'off');
    hide(this.ariaRegionTarget);
    this.suggestionTarget.innerHTML = '';
  }
}
