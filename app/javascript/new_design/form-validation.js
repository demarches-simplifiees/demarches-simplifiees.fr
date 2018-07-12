$(document).on('blur keydown', 'input, textarea', () => {
  $(this).addClass('touched');
});

$(document).on('click', 'input[type="submit"]:not([formnovalidate])', () => {
  const $form = $(this).closest('form');
  $('input, textarea', $form).addClass('touched');
});
