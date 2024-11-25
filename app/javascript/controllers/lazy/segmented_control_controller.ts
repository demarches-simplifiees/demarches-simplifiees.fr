import { Controller } from '@hotwired/stimulus';

export default class SegmentedControlController extends Controller {
  static targets = ['simple', 'advanced'];

  declare readonly simpleTarget: HTMLElement;
  declare readonly advancedTarget: HTMLElement;

  toggle(event: Event) {
    const target = event.target as HTMLInputElement;
    const mode = target.dataset.modeToShow;

    if (mode == 'simple') {
      this.simpleTarget.classList.remove('hidden');
      this.advancedTarget.classList.add('hidden');
    }

    if (mode == 'advanced') {
      this.simpleTarget.classList.add('hidden');
      this.advancedTarget.classList.remove('hidden');
    }
  }
}
