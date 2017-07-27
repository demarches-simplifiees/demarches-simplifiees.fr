$(document).on('blur keydown', 'input, textarea', function() {
  $(this).addClass('touched');
});

$(document).on('click', 'input[type="submit"]:not([formnovalidate])', function() {
  var $form = $(this).closest('form');
  $('input, textarea', $form).addClass('touched');
});
