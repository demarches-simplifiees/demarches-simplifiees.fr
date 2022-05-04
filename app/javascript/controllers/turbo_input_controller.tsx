import { httpRequest } from '@utils';

import { ApplicationController } from './application_controller';

export class TurboInputController extends ApplicationController {
  static values = {
    url: String
  };

  declare readonly urlValue: string;

  connect(): void {
    this.on('input', () => this.debounce(this.load, 200));
  }

  private load(): void {
    const target = this.element as HTMLInputElement;
    const url = new URL(this.urlValue, document.baseURI);
    url.searchParams.append(target.name, target.value);
    httpRequest(url.toString()).turbo();
  }
}
