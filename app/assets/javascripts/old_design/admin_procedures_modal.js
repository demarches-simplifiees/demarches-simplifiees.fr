/* globals $ */

$(document).on('turbolinks:load', init_path_modal);

var PROCEDURE_PATH_SELECTOR = 'input[data-autocomplete=path]';

function init_path_modal() {
  path_modal_action();
  path_validation_action();
  path_type_init();
  path_validation($(PROCEDURE_PATH_SELECTOR));
}

function path_modal_action() {
  $('#publish-modal').on('show.bs.modal', function(event) {
    $('#publish-modal .modal-body .table .tr-content').hide();

    var button = $(event.relatedTarget); // Button that triggered the modal
    var modal_title = button.data('modal_title'); // Extract info from data-* attributes
    var modal_index = button.data('modal_index'); // Extract info from data-* attributes

    var modal = $(this);
    modal.find('#publish-modal-title').html(modal_title);
    $('#publish-modal .modal-body .table #' + modal_index).show();
  });
}

function path_validation_action() {
  $(PROCEDURE_PATH_SELECTOR).keyup(function(key) {
    if (key.keyCode != 13) path_validation(this);
  });
}

function togglePathMessage(valid, mine) {
  $('#path-messages .message').hide();

  if (valid === true && mine === true) {
    $('#path_is_mine').show();
  } else if (valid === true && mine === false) {
    $('#path_is_not_mine').show();
  } else if (valid === false && mine === null) {
    $('#path_is_invalid').show();
  }

  if ((valid && mine === null) || mine === true)
    $('#publish-modal #publish').removeAttr('disabled');
  else $('#publish-modal #publish').attr('disabled', 'disabled');
}

function path_validation(el) {
  var valid = validatePath($(el).val());
  toggleErrorClass(el, valid);
  togglePathMessage(valid, null);
}

function toggleErrorClass(node, boolean) {
  if (boolean) $(node).removeClass('input-error');
  else $(node).addClass('input-error');
}

function validatePath(path) {
  var re = /^[a-z0-9_-]{3,50}$/;
  return re.test(path);
}

function path_type_init() {
  $(PROCEDURE_PATH_SELECTOR).on('autocomplete:select', function(event) {
    togglePathMessage(true, event.detail['mine']);
  });
}
