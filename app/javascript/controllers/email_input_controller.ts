import { hide, show } from '@utils';

import { ApplicationController } from './application_controller';
import { httpRequest } from '@utils';

type checkEmailResponse = {
  success: boolean;
  suggestions: string[];
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
    if (
      !this.inputTarget.value ||
      this.inputTarget.value.length < 5 ||
      !this.inputTarget.value.includes('@')
    ) {
      return;
    }

    const url = new URL(this.urlValue, document.baseURI);
    url.searchParams.append('email', this.inputTarget.value);

    const data: checkEmailResponse | null = await httpRequest(
      url.toString()
    ).json();

    if (data && data.suggestions && data.suggestions.length > 0) {
      this.suggestionTarget.innerHTML = data.suggestions[0];
      show(this.ariaRegionTarget);
      this.ariaRegionTarget.focus();
    }
  }

  accept() {
    hide(this.ariaRegionTarget);
    this.inputTarget.value = this.suggestionTarget.innerHTML;
    this.suggestionTarget.innerHTML = '';
    const nextTarget = document.querySelector<HTMLElement>(
      '[data-email-input-target="next"]'
    );
    if (nextTarget) {
      nextTarget.focus();
    }
  }

  discard() {
    hide(this.ariaRegionTarget);
    this.suggestionTarget.innerHTML = '';
    const nextTarget = document.querySelector<HTMLElement>(
      '[data-email-input-target="next"]'
    );
    if (nextTarget) {
      nextTarget.focus();
    }
  }
}
