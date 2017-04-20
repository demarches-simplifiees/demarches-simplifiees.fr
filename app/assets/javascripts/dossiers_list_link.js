$(document).on('turbolinks:load', link_init);

function link_init() {
  $('#dossiers-list tr').on('click', function () {
    $(location).attr('href', $(this).data('dossier_url'))
  });
}
