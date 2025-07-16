import { hide, httpRequest, show } from '@utils';
import { ApplicationController } from './application_controller';

type CheckEmailResponse =
  | {
      success: true;
      suggestions?: string[];
    }
  | { success: false };

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

    const data = await httpRequest(url.toString(), { method: 'POST' })
      .json<CheckEmailResponse>()
      .catch(() => null);

    if (data?.success) {
      const suggestion = data.suggestions?.at(0);
      if (suggestion) {
        this.suggestionTarget.innerHTML = suggestion;
        show(this.ariaRegionTarget);
        this.ariaRegionTarget.focus();
      }
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
