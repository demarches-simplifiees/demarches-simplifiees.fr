import { ApplicationController } from './application_controller';

interface HTMLTurboFrameElement extends HTMLElement {
  src: string | null;
}

export default class LazyModalController extends ApplicationController {
  static targets = ['frame'];

  declare readonly frameTarget: HTMLTurboFrameElement;

  load(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement;
    const frame = this.frameTarget;

    const src = button.getAttribute('src');
    if (src) {
      frame.src = src;
    }
  }
}
