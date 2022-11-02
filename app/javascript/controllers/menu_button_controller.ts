import { ApplicationController } from './application_controller';

export class MenuButtonController extends ApplicationController {
  static targets = ['button', 'menu'];

  declare readonly buttonTarget: HTMLButtonElement;
  declare readonly menuTarget: HTMLElement;

  #isOpen = false;
  #teardown?: () => void;

  connect() {
    this.setup();
  }

  disconnect(): void {
    this.#teardown?.();
  }

  private get isMenu() {
    return !(this.element as HTMLElement).dataset.popover;
  }

  private setup() {
    this.buttonTarget.setAttribute(
      'aria-haspopup',
      this.isMenu ? 'menu' : 'true'
    );
    this.buttonTarget.setAttribute('aria-controls', this.menuTarget.id);
    if (!this.buttonTarget.id) {
      this.buttonTarget.id = `${this.menuTarget.id}_button`;
    }

    this.menuTarget.setAttribute('aria-labelledby', this.buttonTarget.id);
    this.menuTarget.setAttribute('role', this.isMenu ? 'menu' : 'region');
    this.menuTarget.classList.add('fade-in-down');
    this.menuTarget.setAttribute('tab-index', '-1');

    if (this.isMenu) {
      for (const menuItem of this.menuTarget.querySelectorAll('a')) {
        menuItem.setAttribute('role', 'menuitem');
      }
      for (const dropdownItems of this.menuTarget.querySelectorAll(
        '.dropdown-items'
      )) {
        dropdownItems.setAttribute('role', 'none');
      }
      for (const dropdownItems of this.menuTarget.querySelectorAll(
        '.dropdown-items > li'
      )) {
        dropdownItems.setAttribute('role', 'none');
      }
    }

    this.on('click', (event) => {
      const target = event.target as HTMLElement;
      if (this.buttonTarget == target || this.buttonTarget.contains(target)) {
        event.preventDefault();

        if (this.#isOpen) {
          this.close();
        } else {
          this.open();
        }
      }
    });
    this.on('keydown', (event: KeyboardEvent) => {
      const target = event.target as HTMLElement;
      if (this.buttonTarget == target) {
        this.onButtonKeydown(event);
      } else if (
        this.isMenu &&
        (this.menuTarget == target || this.menuTarget.contains(target))
      ) {
        this.onMenuKeydown(event);
      }
    });
  }

  private open(focusMenuItem: 'first' | 'last' = 'first') {
    this.buttonTarget.setAttribute('aria-expanded', 'true');
    this.menuTarget.parentElement?.classList.add('open');
    this.menuTarget.focus();

    const onClickBody = (event: Event) => {
      const target = event.target as HTMLElement;
      if (this.isClickOutside(target)) {
        this.menuTarget.classList.remove('fade-in-down');
        this.close();
      }
    };
    requestAnimationFrame(() => {
      if (focusMenuItem == 'first') {
        this.setFocusToFirstMenuitem();
      } else {
        this.setFocusToLastMenuitem();
      }
      document.body.addEventListener('click', onClickBody);
    });

    this.#isOpen = true;
    this.#teardown = () =>
      document.body.removeEventListener('click', onClickBody);
  }

  private close() {
    this.buttonTarget.removeAttribute('aria-expanded');
    this.menuTarget.parentElement?.classList.remove('open');
    this.#teardown?.();
    this.setFocusToMenuitem(null);
    this.#isOpen = false;
  }

  private isClickOutside(target: HTMLElement) {
    return (
      target.isConnected &&
      !this.element.contains(target) &&
      !target.closest('reach-portal') &&
      this.#isOpen
    );
  }

  private get currentMenuItem() {
    return this.menuTarget.querySelector<HTMLElement>(
      '[role="menuitem"]:focus'
    );
  }

  private get menuItems() {
    return [
      ...this.menuTarget.querySelectorAll<HTMLElement>('[role="menuitem"]')
    ];
  }

  private setFocusToMenuitem(menuItem: HTMLElement | null) {
    if (menuItem) {
      menuItem.focus();
    } else {
      this.buttonTarget.focus();
    }
  }

  private setFocusToFirstMenuitem() {
    this.setFocusToMenuitem(this.menuItems[0]);
  }

  private setFocusToLastMenuitem() {
    const length = this.menuItems.length;
    this.setFocusToMenuitem(this.menuItems[length - 1]);
  }

  setFocusToPreviousMenuitem() {
    const { currentMenuItem, menuItems } = this;

    if (currentMenuItem) {
      const index = menuItems.indexOf(currentMenuItem);
      if (index == 0) {
        this.setFocusToLastMenuitem();
      } else {
        this.setFocusToMenuitem(menuItems[index - 1]);
      }
    }
  }

  setFocusToNextMenuitem() {
    const { currentMenuItem, menuItems } = this;

    if (currentMenuItem) {
      const index = menuItems.indexOf(currentMenuItem);
      if (index == menuItems.length - 1) {
        this.setFocusToFirstMenuitem();
      } else {
        this.setFocusToMenuitem(menuItems[index + 1]);
      }
    }
  }

  performMenuAction(target: EventTarget | null) {
    target?.dispatchEvent(new Event('click'));
  }

  private onButtonKeydown(event: KeyboardEvent) {
    let stopPropagation = false;
    switch (event.key) {
      case ' ':
      case 'Enter':
      case 'ArrowDown':
      case 'Down':
        this.open();
        stopPropagation = true;
        break;
      case 'Esc':
      case 'Escape':
        this.close();
        stopPropagation = true;
        break;
      case 'Up':
      case 'ArrowUp':
        this.open('last');
        stopPropagation = true;
        break;
      default:
        break;
    }

    if (stopPropagation) {
      event.stopPropagation();
      event.preventDefault();
    }
  }

  onMenuKeydown(event: KeyboardEvent) {
    let stopPropagation = false;
    if (event.ctrlKey || event.altKey || event.metaKey) {
      return;
    }

    if (event.shiftKey) {
      if (event.key == 'Tab') {
        this.close();
        stopPropagation = true;
      }
    } else {
      switch (event.key) {
        case ' ':
          this.performMenuAction(event.target);
          stopPropagation = true;
          break;
        case 'Esc':
        case 'Escape':
          this.close();
          stopPropagation = true;
          break;
        case 'Up':
        case 'ArrowUp':
          this.setFocusToPreviousMenuitem();
          stopPropagation = true;
          break;
        case 'ArrowDown':
        case 'Down':
          this.setFocusToNextMenuitem();
          stopPropagation = true;
          break;
        case 'Home':
        case 'PageUp':
          this.setFocusToFirstMenuitem();
          stopPropagation = true;
          break;
        case 'End':
        case 'PageDown':
          this.setFocusToLastMenuitem();
          stopPropagation = true;
          break;
        case 'Tab':
          this.close();
          break;
        default:
          break;
      }
    }

    if (stopPropagation) {
      event.stopPropagation();
      event.preventDefault();
    }
  }
}
