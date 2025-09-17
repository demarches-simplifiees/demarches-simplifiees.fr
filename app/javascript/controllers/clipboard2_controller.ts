/**
 * Usage:
 * 1. Add `{ "data-controller": "clipboard2" }` to a parent container
 * 2. Mark copyable elements with `.copy-btn`
 * 3. Optionally use `data-to-copy` attribute to specify exact text to copy
 * 4. Optionally use `data-copy-message-placeholder` to control message placement
 */
import { Controller } from '@hotwired/stimulus';

const SUCCESS_MESSAGE_TIMEOUT = 1500;

export class Clipboard2Controller extends Controller {
  static values = {
    copyText: String,
    copiedText: String
  };

  declare readonly copyTextValue: string;
  declare readonly copiedTextValue: string;

  #copySpan!: HTMLElement;
  #copiedSpan!: HTMLElement;
  #timer?: ReturnType<typeof setTimeout>;

  connect(): void {
    if (!navigator.clipboard) {
      return;
    }

    // Create spans with localized text
    this.#copySpan = this.createSpan(this.copyTextValue, [
      'fr-icon-clipboard-line'
    ]);
    this.#copiedSpan = this.createSpan(this.copiedTextValue, [
      'fr-icon-check-line'
    ]);

    this.setupChampHoverListeners();
  }

  private setupChampHoverListeners(): void {
    [...this.element.querySelectorAll<HTMLElement>('.copy-btn')]
      // cannot use innerText because of possible hidden/folded elements
      .filter((wrapper) => wrapper.textContent?.trim() !== '')
      .forEach((wrapper) => {
        wrapper.addEventListener('mouseenter', () => {
          this.insertSpan(wrapper, this.#copySpan);
        });

        wrapper.addEventListener('mouseleave', () => {
          this.#copySpan.remove();
        });

        wrapper.addEventListener('click', (e) => {
          e.preventDefault();
          e.stopPropagation();
          this.copyContent(wrapper);
        });
      });
  }

  private copyContent(wrapper: HTMLElement): void {
    this.#copySpan.remove();

    const textToCopy = (
      wrapper.querySelector<HTMLElement>('[data-to-copy]')?.innerText ||
      wrapper.innerText ||
      ''
    ).trim();

    navigator.clipboard
      .writeText(textToCopy)
      .then(() => this.showCopiedSpan(wrapper));
  }

  private showCopiedSpan(wrapper: HTMLElement): void {
    this.insertSpan(wrapper, this.#copiedSpan);

    clearTimeout(this.#timer);
    this.#timer = setTimeout(() => {
      this.#copiedSpan.remove();
    }, SUCCESS_MESSAGE_TIMEOUT);
  }

  private insertSpan(wrapper: HTMLElement, span: HTMLElement): void {
    const placeholder = wrapper.querySelector<HTMLElement>(
      '[data-copy-message-placeholder]'
    );

    if (placeholder) {
      placeholder.appendChild(span);
      return;
    }

    const lastChild = wrapper.lastElementChild;

    if (lastChild && lastChild.tagName !== 'BR') {
      lastChild.appendChild(span);
    } else {
      wrapper.appendChild(span);
    }
  }

  private createSpan(message: string, classes: string[]): HTMLSpanElement {
    const span = document.createElement('span');
    span.textContent = message;
    span.setAttribute('aria-hidden', 'true');
    const classes_to_add = [
      'fr-ml-1v',
      'fr-badge',
      'fr-badge--sm',
      'fr-badge--blue-cumulus',
      'fr-badge--icon-left',
      'copy-message'
    ];
    span.classList.add(...classes_to_add, ...classes);
    return span;
  }
}
