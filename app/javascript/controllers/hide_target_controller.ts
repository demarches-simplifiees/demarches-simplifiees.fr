import { Controller } from '@hotwired/stimulus';

export class HideTargetController extends Controller {
  static targets = ['source', 'toHide'];
  declare readonly toHideTarget: HTMLDivElement;
  declare readonly sourceTarget: HTMLInputElement;

  connect() {
    this.sourceTarget.addEventListener('input', this.handleInput.bind(this));
  }

  handleInput() {
    const classList = this.toHideTarget.classList;
    this.sourceTarget.checked
      ? classList.remove('fr-hidden')
      : classList.add('fr-hidden');
  }
}
