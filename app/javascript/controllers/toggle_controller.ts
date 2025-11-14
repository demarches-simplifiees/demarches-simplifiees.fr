import { ApplicationController } from './application_controller';

export default class ToggleController extends ApplicationController {
  static targets = ['button', 'content'];

  declare readonly buttonTarget: HTMLButtonElement;
  declare readonly contentTarget: HTMLElement;

  private boundHandleClickOutside?: (e: Event) => void;
  private boundHandleKeydown?: (e: KeyboardEvent) => void;

  connect() {
    this.boundHandleClickOutside = this.handleClickOutside.bind(this);
    document.addEventListener('click', this.boundHandleClickOutside);
    this.contentTarget.addEventListener('click', (e) => e.stopPropagation());
  }

  disconnect() {
    if (this.boundHandleClickOutside) {
      document.removeEventListener('click', this.boundHandleClickOutside);
    }
    this.removeKeyboardListener();
  }

  toggle(event: Event) {
    event.preventDefault();
    event.stopPropagation();

    const isExpanded =
      this.buttonTarget.getAttribute('aria-expanded') === 'true';

    if (isExpanded) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    this.buttonTarget.setAttribute('aria-expanded', 'true');
    this.contentTarget.classList.remove('fr-hidden');
    this.contentTarget.style.display = 'block';

    requestAnimationFrame(() => {
      const firstItem =
        this.contentTarget.querySelector<HTMLElement>('[role="menuitem"]');
      firstItem?.focus();
    });

    this.addKeyboardListener();
  }

  close() {
    this.buttonTarget.setAttribute('aria-expanded', 'false');
    this.contentTarget.classList.add('fr-hidden');
    this.contentTarget.style.display = '';

    this.buttonTarget.focus();

    this.removeKeyboardListener();
  }

  handleClickOutside(event: Event) {
    const target = event.target as Node;
    if (
      !this.element.contains(target) &&
      this.buttonTarget.getAttribute('aria-expanded') === 'true'
    ) {
      this.close();
    }
  }

  private addKeyboardListener() {
    if (!this.boundHandleKeydown) {
      this.boundHandleKeydown = this.handleKeydown.bind(this);
    }
    this.contentTarget.addEventListener('keydown', this.boundHandleKeydown);
  }

  private removeKeyboardListener() {
    if (this.boundHandleKeydown) {
      this.contentTarget.removeEventListener(
        'keydown',
        this.boundHandleKeydown
      );
    }
  }

  private handleKeydown(e: KeyboardEvent) {
    const items = Array.from(
      this.contentTarget.querySelectorAll<HTMLElement>('[role="menuitem"]')
    );

    if (items.length === 0) return;

    const currentIndex = items.findIndex((el) => el === document.activeElement);

    let targetIndex: number | null = null;

    switch (e.key) {
      case 'Escape':
        e.preventDefault();
        this.close();
        return;

      case 'ArrowDown':
        targetIndex = (currentIndex + 1) % items.length;
        break;

      case 'ArrowUp':
        targetIndex = (currentIndex - 1 + items.length) % items.length;
        break;

      case 'Home':
        targetIndex = 0;
        break;

      case 'End':
        targetIndex = items.length - 1;
        break;
    }

    if (targetIndex !== null) {
      e.preventDefault();
      items[targetIndex]?.focus();
    }
  }
}
