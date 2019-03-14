import { show, hide, delegate } from '@utils';

delegate('change', '#contact-form #type', event => {
  const type = event.target.value;
  const visibleElements = `[data-contact-type-only="${type}"]`;
  const hiddenElements = `[data-contact-type-only]:not([data-contact-type-only="${type}"])`;

  document.querySelectorAll(visibleElements).forEach(show);
  document.querySelectorAll(hiddenElements).forEach(hide);
});
