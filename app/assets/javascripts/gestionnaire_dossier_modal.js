$(document).on('page:load', modal_action);
$(document).ready(modal_action);

function modal_action() {
    $('#PJmodal').on('show.bs.modal', function (event) {
        var button = $(event.relatedTarget) // Button that triggered the modal
        var modal_title = button.data('modal_title') // Extract info from data-* attributes

        var modal = $(this)
        modal.find('#PJmodal_title').html(modal_title)
    })
}