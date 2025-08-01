import { Controller } from '@hotwired/stimulus';

export class HideTargetController extends Controller {
  static targets = ['source', 'toHide', 'reveal', 'focus'];
  declare readonly toHideTargets: HTMLDivElement[];
  declare readonly sourceTargets: HTMLInputElement[];
  declare readonly revealTargets: HTMLElement[];
  declare readonly focusTargets: HTMLElement[];

  connect() {
    this.sourceTargets.forEach((source) => {
      source.addEventListener('click', this.handleInput.bind(this));
    });

    this.revealTargets?.forEach((el) => {
      el.addEventListener('click', this.handleReveal.bind(this));
    });
  }

  handleInput(event: Event) {
    this.toHideTargets.forEach((toHide) => {
      toHide.classList.toggle('fr-hidden');
    });

    const source = event.currentTarget as HTMLElement;
    const shouldHideSource = source.dataset.hideTargetHideSource === 'true';
    if (shouldHideSource) {
      source.classList.add('fr-hidden');
    }

    if (this.focusTargets.length > 0) {
      const elementToFocus = this.focusTargets[0];

      if (typeof elementToFocus.focus === 'function') {
        setTimeout(() => elementToFocus.focus(), 0);
      }
    }

    const footer = document.querySelector('.fixed-footer') as HTMLElement;
    if (footer) {
      const height = footer.offsetHeight;
      document.body.style.paddingBottom = `${height}px`;
    }
  }

  handleReveal() {
    this.toHideTargets.forEach((toHide) => {
      toHide.classList.add('fr-hidden');
    });

    this.sourceTargets.forEach((source) => {
      source.classList.remove('fr-hidden');
    });

    document.body.style.paddingBottom = '';
  }
}
