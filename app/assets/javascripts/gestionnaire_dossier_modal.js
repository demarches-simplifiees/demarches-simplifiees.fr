$(document).on('turbolinks:load', modal_action);

function modal_action() {
  $('#PJmodal').on('show.bs.modal', function (event) {
    $("#PJmodal .modal-body .table .tr_content").hide();

    var button = $(event.relatedTarget) // Button that triggered the modal
    var modal_title = button.data('modal_title'); // Extract info from data-* attributes
    var modal_index = button.data('modal_index'); // Extract info from data-* attributes

    var modal = $(this)
    modal.find('#PJmodal_title').html(modal_title);
    $("#PJmodal .modal-body .table #"+modal_index).show();
  })
}
