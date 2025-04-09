import { ApplicationController } from './application_controller';

export class LaGaufreController extends ApplicationController {
  connect() {
    const script = document.createElement('script');
    script.src =
      'https://integration.lasuite.numerique.gouv.fr/api/v1/gaufre.js';
    script.async = true;
    script.defer = true;
    script.id = 'lasuite-gaufre-script';
    document.body.appendChild(script);
  }
}
