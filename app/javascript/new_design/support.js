import { show, hide, delegate } from '@utils';

function updateContactElementsVisibility() {
  const contactSelect = document.querySelector('#contact-form #type');
  if (contactSelect) {
    const type = contactSelect.value;
    const visibleElements = `[data-contact-type-only="${type}"]`;
    const hiddenElements = `[data-contact-type-only]:not([data-contact-type-only="${type}"])`;

    document.querySelectorAll(visibleElements).forEach(show);
    document.querySelectorAll(hiddenElements).forEach(hide);
  }
}

addEventListener('turbolinks:load', updateContactElementsVisibility);
delegate('change', '#contact-form #type', updateContactElementsVisibility);
