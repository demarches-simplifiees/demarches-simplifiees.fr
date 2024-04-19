import { toggle } from '@utils';
import { ApplicationController } from './application_controller';

export class AttestationController extends ApplicationController {
  static targets = [
    'layoutToggle',
    'logoMarianneLabelFieldset',
    'logoAttachmentFieldset',
    'preview'
  ];
  static values = {
    logoAttachmentOfficialLabel: String,
    logoAttachmentFreeLabel: String
  };

  declare readonly layoutToggleTarget: HTMLInputElement;
  declare readonly logoMarianneLabelFieldsetTarget: HTMLElement;
  declare readonly logoAttachmentFieldsetTarget: HTMLElement;
  declare readonly previewTarget: HTMLIFrameElement;

  declare readonly logoAttachmentOfficialLabelValue: string;
  declare readonly logoAttachmentFreeLabelValue: string;

  connect() {
    this.layoutToggleTarget.addEventListener('change', () => {
      this.update();
    });

    this.on('turbo:submit-end', () => {
      // eslint-disable-next-line no-self-assign
      this.previewTarget.src = this.previewTarget.src; // reload the iframe
    });
  }

  toggleMaybeNull(event: Event) {
    const checkbox = event.target as HTMLInputElement;
    const visible = checkbox.checked;

    // toggle hidden class on next label element
    checkbox.nextElementSibling
      ?.querySelector('.fr-hint-text')
      ?.classList?.toggle('hidden', !visible);

    document.querySelectorAll('li[data-maybe-null]').forEach((tag) => {
      tag.classList.toggle('hidden', !visible);
    });
  }

  private get isStateLayout() {
    return this.layoutToggleTarget.checked;
  }

  private update() {
    toggle(this.logoMarianneLabelFieldsetTarget, this.isStateLayout);

    const logoAttachmentLabel =
      this.logoAttachmentFieldsetTarget.querySelector('label');

    if (logoAttachmentLabel) {
      logoAttachmentLabel.innerText = this.isStateLayout
        ? this.logoAttachmentOfficialLabelValue
        : this.logoAttachmentFreeLabelValue;
    }
  }
}
