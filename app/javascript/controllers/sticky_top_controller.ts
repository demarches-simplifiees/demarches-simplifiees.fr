import { ApplicationController } from './application_controller';

export class StickyTopController extends ApplicationController {
  // Ajusts top of sticky top components when there is a sticky header.

  connect(): void {
    const header = document.getElementById('sticky-header');

    if (!header) {
      return;
    }

    this.adjustTop(header);

    window.addEventListener('resize', () => this.adjustTop(header));

    this.listenHeaderMutations(header);
  }

  private listenHeaderMutations(header: HTMLElement) {
    const config = { childList: true, subtree: true };

    const callback: MutationCallback = (mutationsList) => {
      for (const mutation of mutationsList) {
        if (mutation.type === 'childList') {
          this.adjustTop(header);
          break;
        }
      }
    };

    const observer = new MutationObserver(callback);
    observer.observe(header, config);
  }

  private adjustTop(header: HTMLElement) {
    const headerHeight = header.clientHeight;

    if (headerHeight > 0) {
      (this.element as HTMLElement).style.top = `${headerHeight + 8}px`;
    }
  }
}
