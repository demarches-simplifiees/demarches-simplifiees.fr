import $ from 'jquery';

$(document).on('click', '.button.dropdown', event => {
  event.stopPropagation();
  const $target = $(event.target);
  if ($target.hasClass('button', 'dropdown')) {
    $target.toggleClass('open');
  }
});
