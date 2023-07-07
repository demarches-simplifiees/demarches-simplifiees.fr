import {
  isSelectElement,
  isCheckboxOrRadioInputElement,
  isTextInputElement,
  isDateInputElement
} from '@utils';
import { ApplicationController } from './application_controller';

const AUTOSUBMIT_DEBOUNCE_DELAY = 500;
const AUTOSUBMIT_DATE_DEBOUNCE_DELAY = 5000;

export class AutosubmitController extends ApplicationController {
  static targets = ['submitter'];

  declare readonly submitterTarget: HTMLButtonElement | HTMLInputElement;
  declare readonly hasSubmitterTarget: boolean;

  #dateTimeChangedInputs = new WeakSet<HTMLInputElement>();

  connect() {
    this.on('input', (event) => this.onInput(event));
    this.on('change', (event) => this.onChange(event));
    this.on('blur', (event) => this.onBlur(event));
  }

  private onChange(event: Event) {
    const target = event.target as HTMLInputElement;
    if (target.disabled || target.hasAttribute('data-no-autosubmit')) return;

    if (
      isSelectElement(target) ||
      isCheckboxOrRadioInputElement(target) ||
      isTextInputElement(target)
    ) {
      if (isDateInputElement(target)) {
        if (target.value.trim() == '' || !isNaN(Date.parse(target.value))) {
          this.#dateTimeChangedInputs.add(target);
          this.debounce(this.submit, AUTOSUBMIT_DATE_DEBOUNCE_DELAY);
        } else {
          this.#dateTimeChangedInputs.delete(target);
          this.cancelDebounce(this.submit);
        }
      } else {
        this.cancelDebounce(this.submit);
        this.submit();
      }
    }
  }

  private onInput(event: Event) {
    const target = event.target as HTMLInputElement;
    if (target.disabled || target.hasAttribute('data-no-autosubmit')) return;

    if (!isDateInputElement(target) && isTextInputElement(target)) {
      this.debounce(this.submit, AUTOSUBMIT_DEBOUNCE_DELAY);
    }
  }

  private onBlur(event: Event) {
    const target = event.target as HTMLInputElement;
    if (target.disabled || target.hasAttribute('data-no-autosubmit')) return;

    if (isDateInputElement(target)) {
      Promise.resolve().then(() => {
        if (this.#dateTimeChangedInputs.has(target)) {
          this.cancelDebounce(this.submit);
          this.submit();
        }
      });
    }
  }

  private submit() {
    const submitter = this.hasSubmitterTarget ? this.submitterTarget : null;
    const form =
      submitter?.form ?? this.element.closest<HTMLFormElement>('form');

    // Safari does not support "formaction" attribute on submitter passed to requestSubmit :(
    if (submitter && navigator.userAgent.indexOf('Safari') > -1) {
      submitter.click();
    } else {
      form?.requestSubmit(submitter);
    }
  }
}
