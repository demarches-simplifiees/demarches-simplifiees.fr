import { ApplicationController } from '~/controllers/application_controller';

export class VisaController extends ApplicationController {
  connect(): void {
    this.on('change', () => this.debounce(this.load, 200));
    const target = this.element as HTMLInputElement;
    if (target.checked) {
      this.updateVisibilityOfAboveFields(target);
      // for react component to be initialized
      window.setTimeout(() => this.updateVisibilityOfAboveFields(target), 1000);
    }
  }

  static CHAMP_SELECTOR = '.editable-champ';
  static REPETITION = 'editable-champ-repetition';
  static CHECKED_VISA_SELECTOR = "input[data-controller='visa']:checked";
  static CHILD_VISA_SELECTOR =
    ':scope > div > ' + VisaController.CHECKED_VISA_SELECTOR;

  private updateVisibilityOfAboveFields(visa: HTMLInputElement) {
    if (visa == null) return;

    let champ: Element | null | undefined;
    champ = visa.closest(VisaController.CHAMP_SELECTOR);
    while ((champ = champ?.previousElementSibling) != null) {
      this.updateVisibility(champ, visa.checked);

      if (
        !visa.checked &&
        champ.classList.contains(VisaController.REPETITION)
      ) {
        this.updateVisibilityOfRepetition(champ);
      } else if (this.checked_visa(champ)) {
        break;
      }
    }
  }

  private updateVisibilityOfRepetition(champ: Element) {
    champ
      .querySelectorAll<HTMLInputElement>(VisaController.CHECKED_VISA_SELECTOR)
      .forEach((node) => this.updateVisibilityOfAboveFields(node));
  }

  private updateVisibility(champ: Element, checked: boolean) {
    const visibility = checked ? 'hidden' : 'visible';
    champ
      .querySelectorAll<HTMLInputElement>('input, select, button, textarea')
      .forEach((node) => (node.disabled = checked));
    champ
      .querySelectorAll<HTMLInputElement>('a.fr-btn')
      .forEach((node) => (node.style.visibility = visibility));
  }

  private checked_visa(champ: Element): boolean {
    return (
      champ.querySelector<HTMLInputElement>(
        VisaController.CHILD_VISA_SELECTOR
      ) != null
    );
  }

  private load(): void {
    const target = this.element as HTMLInputElement;
    this.updateVisibilityOfAboveFields(target);
  }
}
