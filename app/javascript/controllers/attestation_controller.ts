import { toggle } from '@utils';
import { ApplicationController } from './application_controller';

export class AttestationController extends ApplicationController {
  static targets = [
    'layoutToggle',
    'logoMarianneLabelFieldset',
    'logoAttachmentFieldset'
  ];
  static values = {
    logoAttachmentOfficialLabel: String,
    logoAttachmentFreeLabel: String
  };

  declare readonly layoutToggleTarget: HTMLInputElement;
  declare readonly logoMarianneLabelFieldsetTarget: HTMLElement;
  declare readonly logoAttachmentFieldsetTarget: HTMLElement;

  declare readonly logoAttachmentOfficialLabelValue: string;
  declare readonly logoAttachmentFreeLabelValue: string;

  connect() {
    this.layoutToggleTarget.addEventListener('change', () => {
      this.update();
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
