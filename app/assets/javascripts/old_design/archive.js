/* globals $ */

$(document).on('click', 'button#archive-procedure', function() {
  $('button#archive-procedure').hide();
  $('#confirm').show();
});

$(document).on('click', '#confirm #cancel', function() {
  $('button#archive-procedure').show();
  $('#confirm').hide();
});
