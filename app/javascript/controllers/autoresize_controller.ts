import { ApplicationController } from './application_controller';
import { attach } from '@frsource/autoresize-textarea';
import { isTextAreaElement } from '@coldwired/utils';

export class AutoresizeController extends ApplicationController {
  #detach?: () => void;
  connect(): void {
    if (isTextAreaElement(this.element)) {
      this.#detach = attach(this.element)?.detach;
      this.element.classList.add('resize-none');
    }
  }

  disconnect(): void {
    this.#detach?.();
    this.element.classList.remove('resize-none');
  }
}
