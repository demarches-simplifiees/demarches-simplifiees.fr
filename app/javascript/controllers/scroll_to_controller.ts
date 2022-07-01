import { ApplicationController } from './application_controller';

export class ScrollToController extends ApplicationController {
  static targets = ['to'];
  declare readonly toTarget: HTMLInputElement;
  declare readonly hasToTarget: boolean;

  connect() {
    if (this.hasToTarget) {
      this.scrollToElement();
    } else {
      this.scrollToBottom();
    }
  }

  private scrollTo(top: number) {
    this.element.scrollTop = top;
  }

  private scrollToElement() {
    this.scrollTo(
      offset(this.toTarget).top -
        offset(this.element).top +
        this.element.scrollTop
    );
  }

  private scrollToBottom() {
    this.scrollTo(this.element.scrollHeight);
  }
}

function offset(element: Element) {
  const rect = element.getBoundingClientRect();
  return {
    top: rect.top + document.body.scrollTop,
    left: rect.left + document.body.scrollLeft
  };
}
