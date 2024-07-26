import { Controller } from '@hotwired/stimulus';

export class HideTargetController extends Controller {
  static targets = ['source', 'toHide'];
  declare readonly toHideTargets: HTMLDivElement[];
  declare readonly sourceTargets: HTMLInputElement[];

  connect() {
    this.sourceTargets.forEach((source) => {
      source.addEventListener('click', this.handleInput.bind(this));
    });
  }

  handleInput() {
    this.toHideTargets.forEach((toHide) => {
      toHide.classList.toggle('fr-hidden');
    });
  }
}
