import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['pastToggle', 'futureToggle'];

  declare readonly pastToggleTarget: HTMLInputElement;
  declare readonly futureToggleTarget: HTMLInputElement;

  togglePast() {
    if (this.pastToggleTarget.checked) {
      this.futureToggleTarget.checked = false;
    }
  }

  toggleFuture() {
    if (this.futureToggleTarget.checked) {
      this.pastToggleTarget.checked = false;
    }
  }
}
