import { httpRequest } from '@utils';

import { ApplicationController } from './application_controller';

export class NumeroDnController extends ApplicationController {
  static values = {
    url: String,
    type: String
  };

  declare readonly urlValue: string;
  declare readonly typeValue: string;

  connect(): void {
    this.on('input', () => this.debounce(this.load, 200));
  }

  private load(): void {
    const target = this.element as HTMLInputElement;
    if (!target?.validity?.patternMismatch) {
      const side_type = this.typeValue == 'dn' ? 'ddn' : 'dn';
      const side_element = this.sideElement(target, side_type);
      if (side_element.checkValidity()) {
        const url = new URL(this.urlValue, document.baseURI);
        url.searchParams.append(this.typeValue, target.value);
        url.searchParams.append(side_type, side_element.value);
        httpRequest(url.toString()).turbo();
      } else {
        this.clearInfo(target);
      }
    } else {
      this.clearInfo(target);
    }
  }

  private clearInfo(target: HTMLInputElement) {
    const info = target?.parentElement?.querySelector('.numero-dn-info');
    if (info && info.innerHTML.length > 0) info.innerHTML = '';
  }

  selector(type: string): string {
    return 'input[data-numero-dn-type-value="' + type + '"]';
  }

  sideElement(input: HTMLInputElement, side_type: string): HTMLInputElement {
    return input.parentElement?.querySelector(
      this.selector(side_type)
    ) as HTMLInputElement;
  }
}
