$(document).on('click', 'body', () => {
  $('.button.dropdown').removeClass('open');
});

$(document).on('click', '.button.dropdown', event => {
  event.stopPropagation();
  const $target = $(event.target);
  if ($target.hasClass('button', 'dropdown')) {
    $target.toggleClass('open');
  }
});
