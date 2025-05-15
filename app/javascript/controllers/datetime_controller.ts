import { format } from 'date-fns/format';

import { ApplicationController } from './application_controller';

export class DatetimeController extends ApplicationController {
  #isSupported = isDateTimeSupported();

  connect() {
    if (!this.#isSupported) {
      const value = this.element.getAttribute('value');
      if (value) {
        const date = new Date(value);
        this.element.setAttribute('value', format(date, `dd/MM/yyyy HH:mm`));
      }
    }
  }
}

function isDateTimeSupported() {
  const input = document.createElement('input');
  const value = 'a';
  input.setAttribute('type', 'datetime-local');
  input.setAttribute('value', value);
  return input.value !== value;
}
