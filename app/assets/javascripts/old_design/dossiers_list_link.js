/* globals $ */

$(document).on('click', '#dossiers-list tr', function(event) {
  var href = $(this).data('href');
  if (href && event.target.tagName !== 'A') {
    location.href = href;
  }
});
