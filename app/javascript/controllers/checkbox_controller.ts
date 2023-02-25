import { ApplicationController } from './application_controller';

export class CheckboxController extends ApplicationController {
  onChange() {
    const form = this.element as HTMLFormElement;
    form.requestSubmit();
  }
}
