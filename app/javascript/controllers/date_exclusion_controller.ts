import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['pastToggle', 'futureToggle'];

  declare readonly pastToggleTarget: HTMLInputElement;
  declare readonly futureToggleTarget: HTMLInputElement;
  declare readonly hasPastToggleTarget: boolean;
  declare readonly hasFutureToggleTarget: boolean;

  connect() {
    console.log('Date exclusion controller connected');
    this.updateToggles();
  }

  togglePast(event: Event) {
    const target = event.target as HTMLInputElement;
    console.log('Toggle past clicked', target.checked);
    if (target.checked && this.hasFutureToggleTarget) {
      this.futureToggleTarget.checked = false;
    }
  }

  toggleFuture(event: Event) {
    const target = event.target as HTMLInputElement;
    console.log('Toggle future clicked', target.checked);
    if (target.checked && this.hasPastToggleTarget) {
      this.pastToggleTarget.checked = false;
    }
  }

  private updateToggles() {
    if (this.hasPastToggleTarget && this.hasFutureToggleTarget) {
      if (this.pastToggleTarget.checked && this.futureToggleTarget.checked) {
        this.futureToggleTarget.checked = false;
      }
    }
  }
}
