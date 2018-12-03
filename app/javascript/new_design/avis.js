import { toggle } from '@utils';

export function toggleCondidentielExplanation() {
  toggle(document.querySelector('.confidentiel-explanation'));
}

export function replaceSemicolonByComma(event) {
  event.target.value = event.target.value.replace(/;/g, ',');
}
