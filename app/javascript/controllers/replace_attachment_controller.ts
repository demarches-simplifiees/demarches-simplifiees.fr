import { ApplicationController } from './application_controller';
import { show } from '@utils';

export class ReplaceAttachmentController extends ApplicationController {
  static targets = ['input'];

  declare readonly inputTarget: HTMLInputElement;

  open(event: Event) {
    show(this.inputTarget);
    this.inputTarget.click(); // opens input prompt

    const target = event.currentTarget as HTMLButtonElement;

    if (target.dataset.autoAttachUrl) {
      // set the auto attach url specific to this button to replace the related attachment
      this.inputTarget.dataset.originalAutoAttachUrl =
        this.inputTarget.dataset.autoAttachUrl;

      this.inputTarget.dataset.autoAttachUrl = target.dataset.autoAttachUrl;

      // reset autoAttachUrl which would add an attachment
      // when replace is not finalized
      this.on(this.inputTarget, 'cancel', () => {
        this.inputTarget.dataset.autoAttachUrl =
          this.inputTarget.dataset.originalAutoAttachUrl;
      });
    }
  }
}
