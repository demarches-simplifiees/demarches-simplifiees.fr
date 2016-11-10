$(document).on('page:load', link_init);
$(document).ready(link_init);


function link_init() {
    $('#dossiers_list tr').on('click', function () {
        $(location).attr('href', $(this).data('dossier_url'))
    });
}