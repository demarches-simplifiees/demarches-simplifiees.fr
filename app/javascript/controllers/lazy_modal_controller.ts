import { ApplicationController } from './application_controller';

interface HTMLTurboFrameElement extends HTMLElement {
  src: string | null;
}

declare const window: Window &
  typeof globalThis & { dsfr?: (el: HTMLElement) => { modal: unknown } };

export default class LazyModalController extends ApplicationController {
  static targets = ['frame'];

  declare readonly frameTarget: HTMLTurboFrameElement;

  load(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement;
    const frame = this.frameTarget;

    const src = button.getAttribute('src');
    if (src) {
      frame.src = src;

      frame.addEventListener(
        'turbo:frame-load',
        () => {
          const modalId = button.getAttribute('aria-controls');
          if (modalId) {
            const modal = document.getElementById(modalId);
            if (modal && window.dsfr) {
              // @ts-expect-error type not enforced
              window.dsfr(modal).modal.disclose();
            }
          }
        },
        { once: true }
      );
    }
  }
}
