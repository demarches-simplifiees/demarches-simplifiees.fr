import { Controller } from '@hotwired/stimulus';

export class TiptapToTemplateController extends Controller {
  static targets = ['output', 'trigger'];

  declare readonly outputTarget: HTMLElement;
  declare readonly triggerTarget: HTMLButtonElement;

  connect() {
    this.triggerTarget.addEventListener('click', this.handleClick.bind(this));
  }

  handleClick() {
    const template = this.element.querySelector('.tiptap.ProseMirror p');

    if (template) {
      this.outputTarget.innerHTML = template.innerHTML;
    }
  }
}
