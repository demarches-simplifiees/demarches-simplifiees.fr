$(document).on('turbolinks:load', link_init);

function link_init() {
  $('#dossiers-list tr').on('click', function(event) {
    var href = $(this).data('href');
    if (href && event.target.tagName !== 'A') {
      location.href = href;
    }
  });
}
