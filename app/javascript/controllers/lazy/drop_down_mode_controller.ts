import { Controller } from '@hotwired/stimulus';

export default class DropDownModeController extends Controller {
  static targets = ['manual', 'referentiel' ];

  declare readonly manualTarget: HTMLElement[];
  declare readonly referentielTarget: HTMLElement[];


  toggle(event: Event) {
    const target = event.target as HTMLInputElement;
    const mode = target.dataset.modeToShow;

    if (mode == 'manual') {
      this.manualTarget.classList.remove("hidden");
      this.referentielTarget.classList.add("hidden");
    };

    if (mode == 'referentiel') {
      this.manualTarget.classList.add("hidden");
      this.referentielTarget.classList.remove("hidden");
    };
  }
}
