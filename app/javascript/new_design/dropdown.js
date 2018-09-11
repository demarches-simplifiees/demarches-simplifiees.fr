import Rails from 'rails-ujs';

const { delegate } = Rails;

delegate(document, 'body', 'click', event => {
  if (!event.target.closest('.dropdown')) {
    [...document.querySelectorAll('.dropdown')].forEach(element =>
      element.classList.remove('open', 'fade-in-down')
    );
  }
});

delegate(document, '.dropdown-button', 'click', event => {
  event.stopPropagation();
  const parent = event.target.closest('.dropdown-button').parentElement;
  if (parent.classList.contains('dropdown')) {
    parent.classList.toggle('open');
  }
});
