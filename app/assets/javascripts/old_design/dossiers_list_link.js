$(document).on('turbolinks:load', link_init);

function link_init() {
  $('#dossiers-list tr').on('click', function (event) {
    if (event.target.className !== 'btn-sm btn-danger') {
      $(location).attr('href', $(this).data('dossier_url'));
    }
  });
}
