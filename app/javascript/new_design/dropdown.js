import { delegate } from '@utils';

delegate('click', 'body', (event) => {
  if (!event.target.closest('.dropdown')) {
    [...document.querySelectorAll('.dropdown')].forEach((element) => {
      const button = element.querySelector('.dropdown-button');
      button.setAttribute('aria-expanded', false);
      element.classList.remove('open', 'fade-in-down');
    });
  }
});

delegate('click', '.dropdown-button', (event) => {
  event.stopPropagation();
  const button = event.target.closest('.dropdown-button');
  const parent = button.parentElement;
  if (parent.classList.contains('dropdown')) {
    parent.classList.toggle('open');
    var buttonExpanded = button.getAttribute('aria-expanded') === 'true';
    button.setAttribute('aria-expanded', !buttonExpanded);
  }
});
