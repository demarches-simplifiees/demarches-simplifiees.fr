import { httpRequest } from '@utils';
import { ApplicationController } from './application_controller';

export class DossierFilterController extends ApplicationController {
  onChange() {
    const element = this.element as HTMLFormElement;

    httpRequest(element.action, {
      method: element.getAttribute('method') ?? '',
      body: new FormData(element)
    }).turbo();
  }
}
