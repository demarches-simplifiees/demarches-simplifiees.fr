import { httpRequest } from '@utils';

import { ApplicationController } from './application_controller';

export class NumeroDnController extends ApplicationController {
  static values = { url: String };

  declare readonly urlValue: string;

  static targets = ['dn', 'ddn', 'info'];

  declare readonly dnTarget: HTMLInputElement;
  declare readonly ddnTarget: HTMLInputElement;
  declare readonly infoTarget: HTMLInputElement;

  connect(): void {
    this.onTarget(this.dnTarget, 'input', () => this.debounce(this.load, 200));
    this.onTarget(this.ddnTarget, 'input', () => this.debounce(this.load, 200));
  }
  private load(): void {
    if (!this.dnTarget?.validity?.patternMismatch) {
      if (this.ddnTarget.checkValidity()) {
        const url = new URL(this.urlValue, document.baseURI);
        url.searchParams.append('dn', this.dnTarget.value);
        url.searchParams.append('ddn', this.ddnTarget.value);
        httpRequest(url.toString()).turbo();
      } else {
        this.clearInfo();
      }
    } else {
      this.clearInfo();
    }
  }

  private clearInfo() {
    const info = this.infoTarget;
    if (info && info.innerHTML.length > 0) info.innerHTML = '';
  }
}
