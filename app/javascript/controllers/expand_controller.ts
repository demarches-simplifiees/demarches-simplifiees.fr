import { ApplicationController } from './application_controller';
import { toggle, toggleExpandIcon } from '@utils';

export class ExpandController extends ApplicationController {
  static targets = ['content', 'icon'];

  declare readonly contentTarget: HTMLElement;
  declare readonly iconTarget: HTMLElement;

  toggle(event: Event) {
    event.preventDefault();
    toggle(this.contentTarget);
    toggleExpandIcon(this.iconTarget);
  }
}
