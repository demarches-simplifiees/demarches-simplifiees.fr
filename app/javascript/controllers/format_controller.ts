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
        break;
      case 'integer':
        this.on('input', (event) => {
          const target = event.target as HTMLInputElement;
          target.value = this.formatInteger(target.value);
        });
        break;
      case 'decimal':
        this.on('input', (event) => {
          const target = event.target as HTMLInputElement;
          target.value = this.formatDecimal(target.value);
        });
        break;
    }
  }

  private formatList(value: string) {
    return value.replace(/;/g, ',');
  }

  private formatIBAN(value: string) {
    return value
      .replace(/[^\dA-Z]/gi, '')
      .replace(/(.{4})/g, '$1 ')
      .trim()
      .toUpperCase();
  }

  private formatInteger(value: string) {
    return value.replace(/[^-?\d]/g, '');
  }

  private formatDecimal(value: string) {
    // Le séparateur de décimales est toujours après le séparateur de milliers (un point ou une virgule).
    // S'il n'y a qu'un seul séparateur, on considère que c'est celui des décimales.
    // S'il n'y en a pas, ça n'a pas d'effet.
    const decimalSeparator =
      value.lastIndexOf(',') > value.lastIndexOf('.') ? ',' : '.';

    return value.replace(new RegExp(`[^-?\\d${decimalSeparator}]`, 'g'), '');
  }
}
