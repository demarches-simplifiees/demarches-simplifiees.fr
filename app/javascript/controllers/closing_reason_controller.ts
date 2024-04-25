import { ApplicationController } from './application_controller';
import { hide, show } from '@utils';

export class ClosingReasonController extends ApplicationController {
  static targets = ['closingReason', 'replacedByProcedureId', 'closingDetails'];

  declare closingReasonTarget: HTMLSelectElement;
  declare replacedByProcedureIdTarget: HTMLInputElement;
  declare closingDetailsTarget: HTMLInputElement;

  connect() {
    this.displayInput();
    this.on('change', () => this.onChange());
  }

  onChange() {
    this.displayInput();
  }

  displayInput() {
    const closingReasonSelect = this.closingReasonTarget as HTMLSelectElement;

    Array.from(closingReasonSelect.options).forEach((option) => {
      if (option.selected && option.value == 'internal_procedure') {
        show(this.replacedByProcedureIdTarget);
        hide(this.closingDetailsTarget);
        this.emptyValue(this.closingDetailsTarget.querySelector('input'));
      } else if (option.selected && option.value == 'other') {
        hide(this.replacedByProcedureIdTarget);
        this.emptyValue(
          this.replacedByProcedureIdTarget.querySelector('select')
        );
        show(this.closingDetailsTarget);
        this.emptyValue(this.closingDetailsTarget.querySelector('input'));
      }
    });
  }

  emptyValue(field: HTMLInputElement | HTMLSelectElement | null) {
    if (field) {
      field.value = '';
    }
  }
}
