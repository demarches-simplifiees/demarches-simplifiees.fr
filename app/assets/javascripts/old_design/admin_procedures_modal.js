$(document).on('turbolinks:load', init_path_modal);

function init_path_modal() {
  path_modal_action();
  path_validation_action();
  path_type_init();
  path_validation($("input[id='procedure_path']"));
}

function path_modal_action() {
  $('#publish-modal').on('show.bs.modal', function (event) {
    $("#publish-modal .modal-body .table .tr-content").hide();

    var button = $(event.relatedTarget) // Button that triggered the modal
    var modal_title = button.data('modal_title'); // Extract info from data-* attributes
    var modal_index = button.data('modal_index'); // Extract info from data-* attributes

    var modal = $(this)
    modal.find('#publish-modal-title').html(modal_title);
    $("#publish-modal .modal-body .table #"+modal_index).show();
  })
}

function path_validation_action() {
  $("input[id='procedure_path']").keyup(function (key) {
    if (key.keyCode != 13)
      path_validation(this);
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
    $('#publish-modal #publish').removeAttr('disabled')
  else
    $('#publish-modal #publish').attr('disabled', 'disabled')
}

function path_validation(el) {
  var valid = validatePath($(el).val());
  toggleErrorClass(el, valid);
  togglePathMessage(valid, null);
}

function validatePath(path) {
  var re = /^[a-z0-9_\-]{3,50}$/;
  return re.test(path);
}

function path_type_init() {
  $('#procedure_path').bind('autocomplete:select', function(ev, suggestion) {
    togglePathMessage(true, suggestion['mine']);
  });
}

function transfer_errors_message(show) {
  if(show){
    $("#not_found_admin").slideDown(100)
  }
  else {
    $("#not_found_admin").slideUp(100)
  }
}
