import { ApplicationController } from './application_controller';
import * as Turbo from '@hotwired/turbo';

export class ModalRedirectController extends ApplicationController {
  static values = {
    url: String
  };

  declare urlValue: string;

  connect(): void {
    const modal = document.querySelector(
      '#modal-avis-batch'
    ) as HTMLElement | null;
    if (modal) {
      modal.remove();
    }

    if (this.urlValue) {
      Turbo.visit(this.urlValue);
    }
  }
}
