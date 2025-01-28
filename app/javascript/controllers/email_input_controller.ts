import { httpRequest } from '@utils';
import { show, hide } from '@utils';
import { ApplicationController } from './application_controller';

type checkEmailResponse = {
  success: boolean;
  email_suggestions: string[];
};

export class EmailInputController extends ApplicationController {
  static targets = ['ariaRegion', 'suggestion', 'input'];

  static values = {
    url: String
  };

  declare readonly urlValue: string;

  declare readonly ariaRegionTarget: HTMLElement;
  declare readonly suggestionTarget: HTMLElement;
  declare readonly inputTarget: HTMLInputElement;

  async checkEmail() {
    const email = this.inputTarget.value;

    if (!email || email.length < 5 || !email.includes('@')) {
      return;
    }

    if (email.toLowerCase().endsWith('@gmail.pf')) {
      const address = email.substring(0, email.indexOf('@')) + '@gmail.com';
      this.suggestionTarget.innerHTML = address;
      show(this.ariaRegionTarget);
      this.ariaRegionTarget.setAttribute('aria-live', 'assertive');
    } else if (email.toLowerCase().endsWith('.pf')) {
      this.discard();
    } else {
      const url = new URL(this.urlValue, document.baseURI);
      url.searchParams.append('email', email);

      const data: checkEmailResponse | null = await httpRequest(
        url.toString()
      ).json();

      if (data && data.email_suggestions && data.email_suggestions.length > 0) {
        this.suggestionTarget.innerHTML = data.email_suggestions[0];
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
