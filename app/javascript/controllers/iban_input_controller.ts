import { ApplicationController } from './application_controller';

export class IBANInputController extends ApplicationController {
  connect() {
    this.on('input', (event) => {
      const target = event.target as HTMLInputElement;
      target.value = target.value
        .replace(/[^\dA-Z]/g, '')
        .replace(/(.{4})/g, '$1 ')
        .trim();
    });
  }
}
