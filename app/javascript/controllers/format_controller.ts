import { ApplicationController } from './application_controller';

export class FormatController extends ApplicationController {
  connect() {
    const format = this.element.getAttribute('data-format');
    switch (format) {
      case 'list':
        this.on('change', (event) => {
          const target = event.target as HTMLInputElement;
          const value = this.formatList(target.value);
          replaceValue(target, value);
        });
        break;
      case 'iban':
        this.on('input', (event) => {
          const target = event.target as HTMLInputElement;
          const value = this.formatIBAN(target.value);
          replaceValue(target, value);
        });
        break;
      case 'integer':
        this.on('input', (event) => {
          const target = event.target as HTMLInputElement;
          const value = this.formatInteger(target.value);
          replaceValue(target, value);
        });
        break;
      case 'decimal':
        this.on('input', (event) => {
          const target = event.target as HTMLInputElement;
          const value = this.formatDecimal(target.value);
          replaceValue(target, value);
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
    const decimalSeparator = getDecimalSeparator(value);
    const number =
      decimalSeparator == ','
        ? value.replace(/\./g, '').replace(/,/g, '.')
        : value.replace(/,/g, '');
    return number.replace(new RegExp(`[^-?\\d.]`, 'g'), '');
  }
}

function replaceValue(target: HTMLInputElement, value: string) {
  const delta = target.value.length - value.length;
  const start = target.selectionStart;
  const end = target.selectionStart;
  const dir = target.selectionDirection;
  target.value = value;
  target.selectionStart = start ? start - delta : 0;
  target.selectionEnd = end ? end - delta : 0;
  target.selectionDirection = dir;
}

function getDecimalSeparator(value: string) {
  if (value.indexOf('.') != -1 && value.indexOf(',') != -1) {
    if (value.lastIndexOf('.') < value.lastIndexOf(',')) {
      return ',';
    }
    return '.';
  } else if (value.indexOf(',') != -1) {
    return ',';
  }
  return (1.1).toLocaleString().indexOf('.') != -1 ? '.' : ',';
}
