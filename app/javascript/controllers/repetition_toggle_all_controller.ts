import { ApplicationController } from './application_controller';

declare const window: Window &
  typeof globalThis & {
    dsfr?: (el: HTMLElement) => {
      collapse: { disclose: () => void; conceal: () => void };
    };
  };

export class RepetitionToggleAllController extends ApplicationController {
  static targets = ['icon', 'text', 'rowsContainer'];
  static values = {
    expandedText: String,
    collapsedText: String
  };

  declare readonly iconTarget: HTMLElement;
  declare readonly textTarget: HTMLElement;
  declare readonly rowsContainerTarget: HTMLElement;
  declare expandedTextValue: string;
  declare collapsedTextValue: string;

  connect() {
    this.updateButtonState();
    // Listen to accordion changes to update button state
    this.rowsContainerTarget.addEventListener(
      'click',
      this.handleAccordionClick.bind(this),
      true
    );
  }

  disconnect() {
    this.rowsContainerTarget.removeEventListener(
      'click',
      this.handleAccordionClick.bind(this),
      true
    );
  }

  toggleAll(event: Event) {
    event.preventDefault();
    const allExpanded = this.areAllExpanded();
    const shouldExpand = !allExpanded;

    // Find all collapse elements (fr-collapse) in the container
    const collapseElements =
      this.rowsContainerTarget.querySelectorAll<HTMLElement>('.fr-collapse');

    if (!window.dsfr) {
      return;
    }

    collapseElements.forEach((collapseElement) => {
      const dsfrInstance = window.dsfr?.(collapseElement);
      if (dsfrInstance?.collapse) {
        if (shouldExpand) {
          dsfrInstance.collapse.disclose();
        } else {
          dsfrInstance.collapse.conceal();
        }
      }
    });

    // Update button state after a short delay to allow DSFR to update
    setTimeout(() => {
      this.updateButtonState();
    }, 100);
  }

  private handleAccordionClick(event: Event) {
    // Check if the click was on an accordion button
    const target = event.target as HTMLElement;
    if (target.closest('.fr-accordion__btn')) {
      // Update button state after accordion state changes
      setTimeout(() => {
        this.updateButtonState();
      }, 100);
    }
  }

  private areAllExpanded(): boolean {
    const accordionButtons =
      this.rowsContainerTarget.querySelectorAll<HTMLButtonElement>(
        '.fr-accordion__btn'
      );

    if (accordionButtons.length === 0) {
      return false;
    }

    return Array.from(accordionButtons).every(
      (button) => button.getAttribute('aria-expanded') === 'true'
    );
  }

  private updateButtonState() {
    const allExpanded = this.areAllExpanded();

    // Update icon
    if (allExpanded) {
      // Change icon to up arrow (replier)
      this.iconTarget.className = 'fr-icon-arrow-up-s-line';
    } else {
      // Change icon to down arrow (déplier)
      this.iconTarget.className = 'fr-icon-arrow-down-s-line';
    }

    // Update button text
    this.textTarget.textContent = allExpanded
      ? this.expandedTextValue
      : this.collapsedTextValue;
  }
}
