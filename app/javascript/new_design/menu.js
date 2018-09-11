import Rails from 'rails-ujs';

const { delegate } = Rails;

delegate(document, 'body', 'click', function() {
  [...document.querySelectorAll('.open')].forEach(({ classList }) => {
    classList.remove('open', 'fade-in-down');
  });
});
