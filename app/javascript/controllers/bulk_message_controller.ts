import { ApplicationController } from './application_controller';

export class BulkMessage extends ApplicationController {
  declare readonly elementTargets: HTMLInputElement[];
  declare readonly countTarget: HTMLSpanElement;

  static targets = ['element', 'count'];

  change() {
    setTimeout(this.updateCounter.bind(this), 0); // delay execution when click on select all
  }

  private updateCounter() {
    this.countTarget.textContent = this.elementTargets
      .reduce((sum, element) => {
        return element.dataset.count && element.checked
          ? sum + parseInt(element.dataset.count, 10)
          : sum;
      }, 0)
      .toString();
  }
}
