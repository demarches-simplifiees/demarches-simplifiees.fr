/**
 * Usage:
 * 1. Add `{ "data-controller": "clipboard2" }` to a parent container
 * 2. Mark copyable elements with `.copy-zone`
 * 3. Optionally use `data-to-copy` attribute to specify exact text to copy
 * 4. Optionally use `.copy-zone{ 'data-to-copy': 'coucou' }` to copy specific text
 * 5. Optionally use `data-copy-message-placeholder` to control message placement
 */
import { Controller } from '@hotwired/stimulus';

export class Clipboard2Controller extends Controller {
  static values = {
    copyText: String,
    copiedText: String
  };

  declare readonly copyTextValue: string;
  declare readonly copiedTextValue: string;

  connect(): void {
    if (!navigator.clipboard) {
      return;
    }

    this.setupChampHoverListeners();
  }

  private setupChampHoverListeners(): void {
    [...this.element.querySelectorAll<HTMLElement>('.copy-zone')]
      // cannot use innerText because of possible hidden/folded elements
      .filter((wrapper) => wrapper.textContent?.trim() !== '')
      .forEach((wrapper) => {
        const button = this.createButton();
        this.insertButton(wrapper, button);

        button.addEventListener('focus', () => {
          this.setCopyState(button);
        });

        wrapper.addEventListener('mouseenter', () => {
          this.setCopyState(button);
        });

        wrapper.addEventListener('click', (e) => {
          e.preventDefault();
          e.stopPropagation();
          this.copyContent(wrapper);
        });
      });
  }

  private copyContent(wrapper: HTMLElement): void {
    const button = wrapper.querySelector<HTMLButtonElement>('button.copy-btn');

    if (button) {
      button.innerText = '';
    }

    const textToCopy = (
      wrapper.dataset['toCopy'] ||
      wrapper.querySelector<HTMLElement>('[data-to-copy]')?.innerText ||
      wrapper.innerText ||
      ''
    ).trim();

    if (document.hasFocus()) {
      navigator.clipboard.writeText(textToCopy).then(() => {
        if (button) {
          this.setCopiedState(button);
        }
      });
    }
  }

  private insertButton(wrapper: HTMLElement, button: HTMLButtonElement): void {
    const placeholder = wrapper.querySelector<HTMLElement>(
      '[data-copy-message-placeholder]'
    );

    if (placeholder) {
      placeholder.appendChild(button);
      return;
    }

    const lastChild = wrapper.lastElementChild;

    if (lastChild && lastChild.tagName !== 'BR') {
      lastChild.appendChild(button);
    } else {
      wrapper.appendChild(button);
    }
  }

  private createButton(): HTMLButtonElement {
    const button = document.createElement('button');
    button.setAttribute('type', 'button');
    button.setAttribute('aria-live', 'polite');
    button.setAttribute('aria-atomic', 'true');
    button.classList.add(
      'fr-ml-1v',
      'fr-badge',
      'fr-badge--sm',
      'fr-badge--blue-cumulus',
      'fr-badge--icon-left',
      'copy-btn'
    );
    this.setCopyState(button);
    return button;
  }

  private setCopyState(button: HTMLButtonElement): void {
    button.textContent = this.copyTextValue;
    button.classList.add('fr-icon-clipboard-line');
    button.classList.remove('fr-icon-check-line');
  }

  private setCopiedState(button: HTMLButtonElement): void {
    button.textContent = this.copiedTextValue;
    button.classList.remove('fr-icon-clipboard-line');
    button.classList.add('fr-icon-check-line');
  }
}
