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

    let element: Element | null | undefined;
    element = visa.closest(VisaController.CHAMP_SELECTOR);
    while ((element = element?.previousElementSibling) != null) {
      if (this.isTitle(element)) {
        if (this.isSubTitle(element)) {
          element = element.parentElement;
        }
      } else {
        // champ
        this.updateVisibility(element, visa.checked);

        if (!visa.checked && this.isRepetition(element)) {
          this.updateVisibilityOfRepetition(element);
        } else if (this.checked_visa(element)) {
          break;
        }
      }
    }
  }

  private isTitle(element: Element) {
    return element.tagName === 'LEGEND';
  }

  private isSubTitle(champ: Element) {
    return champ.children.length > 0 && champ.children[0].tagName !== 'H2';
  }

  private isRepetition(champ: Element) {
    return champ.classList.contains(VisaController.REPETITION);
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
