import { ApplicationController } from './application_controller';
import { toggle, toggleExpandIcon } from '@utils';

export class ExpandController extends ApplicationController {
  static targets = ['content', 'icon'];

  declare readonly contentTarget: HTMLElement;
  declare readonly iconTarget: HTMLElement;

  toggle(event: Event) {
    const target = event.currentTarget as HTMLButtonElement;

    event.preventDefault();
    toggle(this.contentTarget);
    toggleExpandIcon(this.iconTarget);
    if (this.contentTarget.classList.contains('hidden')) {
      target.setAttribute('aria-expanded', 'false');
    } else {
      target.setAttribute('aria-expanded', 'true');
    }
  }
}
