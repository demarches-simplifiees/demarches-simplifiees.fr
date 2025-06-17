import { ApplicationController } from './application_controller';
import * as Turbo from '@hotwired/turbo';

export class ModalRedirectController extends ApplicationController {
  static targets = ['modal'];
  static values = { url: String };

  declare readonly modalTarget: HTMLElement;
  declare readonly hasModalTarget: boolean;
  declare readonly urlValue: string;

  connect(): void {
    if (this.hasModalTarget) {
      this.modalTarget.remove();
    }

    if (this.urlValue) {
      Turbo.visit(this.urlValue);
    }
  }
}
