import { ApplicationController } from './application_controller';
import { show } from '@utils';

export class ReplaceAttachmentController extends ApplicationController {
  static targets = ['input'];

  declare readonly inputTarget: HTMLInputElement;

  open() {
    show(this.inputTarget);
    this.inputTarget.click(); // opens input prompt
  }
}
