import {} from '@hotwired/stimulus';
import { show, hide } from '~/shared/utils';
import { ApplicationController } from './application_controller';

type AttachementDestroyedEvent = CustomEvent<{ target_id: string }>;

export class AttachmentMultipleController extends ApplicationController {
  static targets = ['buttonAdd', 'empty'];

  declare readonly emptyTarget: HTMLDivElement;
  declare readonly buttonAddTarget: HTMLButtonElement;

  connect() {
    this.onGlobal('attachment:destroyed', (event: AttachementDestroyedEvent) =>
      this.onAttachmentDestroy(event)
    );
  }

  add(event: Event) {
    event.preventDefault();

    hide(this.buttonAddTarget);

    show(this.emptyTarget);

    const inputFile = this.emptyTarget.querySelector(
      'input[type=file]'
    ) as HTMLInputElement;

    inputFile.click();
  }

  onAttachmentDestroy(event: AttachementDestroyedEvent) {
    const { detail } = event;

    const attachmentWrapper = document.getElementById(detail.target_id);

    // Remove this attachment row when there is at least another attachment.
    if (attachmentWrapper && this.attachmentsCount() > 1) {
      attachmentWrapper.parentNode?.removeChild(attachmentWrapper);
    } else {
      hide(this.buttonAddTarget);
    }
  }

  attachmentsCount() {
    // Don't count the hidden "empty" attachment
    return this.element.querySelectorAll('.attachment-input').length - 1;
  }
}
