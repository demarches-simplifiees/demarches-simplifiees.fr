/* globals $ */

$(document).on('click', '.delete', function() {
  $(this).hide();
  $(this)
    .closest('td')
    .find('.confirm')
    .show();
});

$(document).on('click', '.cancel', function() {
  $(this)
    .closest('td')
    .find('.delete')
    .show();
  $(this)
    .closest('td')
    .find('.confirm')
    .hide();
});
