/* globals $ */

$(document).on('turbolinks:load', modal_action);

function modal_action() {
  $('#pj-modal').on('show.bs.modal', function(event) {
    $('#pj-modal .modal-body .table .tr-content').hide();

    var button = $(event.relatedTarget); // Button that triggered the modal
    var modal_title = button.data('modal_title'); // Extract info from data-* attributes
    var modal_index = button.data('modal_index'); // Extract info from data-* attributes

    var modal = $(this);
    modal.find('#pj-modal-title').html(modal_title);
    $('#pj-modal .modal-body .table #' + modal_index).show();
  });
}
