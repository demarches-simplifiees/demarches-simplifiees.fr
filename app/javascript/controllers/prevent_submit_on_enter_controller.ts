import { ApplicationController } from './application_controller';

export class PreventSubmitOnEnterController extends ApplicationController {
  connect(): void {
    this.on('submit', (event: Event) => {
      event.preventDefault();
    });
  }
}
