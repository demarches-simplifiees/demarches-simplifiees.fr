import { ApplicationController } from '~/controllers/application_controller';

export class VisaController extends ApplicationController {
  connect(): void {
    this.on('change', () => this.debounce(this.load, 200));
    const target = this.element as HTMLInputElement;
    if (target.checked) {
      this.freezeFieldAbove(target);
      // for react component to be initialized
      window.setTimeout(() => this.freezeFieldAbove(target), 1000);
    }
  }

  static CHAMP_SELECTOR = '.editable-champ';

  private freezeFieldAbove(visa: HTMLInputElement) {
    const visibility = visa.checked ? 'hidden' : 'visible';
    let champ: Element | null | undefined;
    champ = visa.closest(VisaController.CHAMP_SELECTOR);
    while ((champ = champ?.previousElementSibling)) {
      champ
        .querySelectorAll<HTMLInputElement>('input, select, button, textarea')
        .forEach((node) => (node.disabled = visa.checked));
      champ
        .querySelectorAll<HTMLInputElement>('a.fr-btn')
        .forEach((node) => (node.style.visibility = visibility));
    }
  }

  private load(): void {
    const target = this.element as HTMLInputElement;
    target
      ?.closest('form')
      ?.querySelector<HTMLInputElement>('input[type=submit]')
      ?.click();
  }
}
