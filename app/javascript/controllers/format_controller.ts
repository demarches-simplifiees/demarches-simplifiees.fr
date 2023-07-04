import { ApplicationController } from './application_controller';

export class FormatController extends ApplicationController {
  connect() {
    const format = this.element.getAttribute('data-format');
    switch (format) {
      case 'list':
        this.on('change', (event) => {
          const target = event.target as HTMLInputElement;
          target.value = this.formatList(target.value);
        });
        break;
      case 'iban':
        this.on('input', (event) => {
          const target = event.target as HTMLInputElement;
          target.value = this.formatIBAN(target.value);
        });
    }
  }

  private formatList(value: string) {
    return value.replace(/;/g, ',');
  }

  private formatIBAN(value: string) {
    return value
      .replace(/[^\dA-Z]/g, '')
      .replace(/(.{4})/g, '$1 ')
      .trim();
  }
}
