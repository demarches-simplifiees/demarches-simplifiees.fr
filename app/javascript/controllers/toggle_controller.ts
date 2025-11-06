import { ApplicationController } from './application_controller';

export default class ToggleController extends ApplicationController {
  static targets = ['button', 'content'];

  declare readonly buttonTarget: HTMLButtonElement;
  declare readonly contentTarget: HTMLElement;

  connect() {
    document.addEventListener('click', this.handleClickOutside.bind(this));
    this.contentTarget.addEventListener('click', (e) => e.stopPropagation());
  }

  disconnect() {
    document.removeEventListener('click', this.handleClickOutside.bind(this));
  }

  toggle(event: Event) {
    event.preventDefault();
    event.stopPropagation();

    const isExpanded =
      this.buttonTarget.getAttribute('aria-expanded') === 'true';

    if (isExpanded) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    this.buttonTarget.setAttribute('aria-expanded', 'true');
    this.contentTarget.classList.remove('fr-hidden');
    this.contentTarget.style.display = 'block';
  }

  close() {
    console.log('Closing menu');
    this.buttonTarget.setAttribute('aria-expanded', 'false');
    this.contentTarget.classList.add('fr-hidden');
    this.contentTarget.style.display = '';
  }

  handleClickOutside(event: Event) {
    const target = event.target as Node;
    if (
      !this.element.contains(target) &&
      this.buttonTarget.getAttribute('aria-expanded') === 'true'
    ) {
      this.close();
    }
  }
}
