import { delegate } from '@utils';

delegate('click', 'body', event => {
  if (!event.target.closest('.dropdown')) {
    [...document.querySelectorAll('.dropdown')].forEach(element =>
      element.classList.remove('open', 'fade-in-down')
    );
  }
});

delegate('click', '.dropdown-button', event => {
  event.stopPropagation();
  const parent = event.target.closest('.dropdown-button').parentElement;
  if (parent.classList.contains('dropdown')) {
    parent.classList.toggle('open');
  }
});
