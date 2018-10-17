/* globals $ */

$(document).on('click', '.delete', function() {
  $(this).hide();
  $(this)
    .closest('td')
    .find('.confirm')
    .show();
});

$(document).on('click', '.cancel', function() {
  $(this)
    .closest('td')
    .find('.delete')
    .show();
  $(this)
    .closest('td')
    .find('.confirm')
    .hide();
});

$(document).on('change', 'select.form-control.type-champ', function() {
  var parent = $(this)
    .parent()
    .parent();

  parent.removeClass('header-section');
  parent.children('.drop-down-list').removeClass('show-inline');
  parent.children('.pj-template').removeClass('show-inline');
  parent.children('.carte-options').removeClass('show-inline');

  $('.mandatory', parent).show();

  switch (this.value) {
    case 'header_section':
      parent.addClass('header-section');
      break;
    case 'drop_down_list':
    case 'multiple_drop_down_list':
    case 'linked_drop_down_list':
      parent.children('.drop-down-list').addClass('show-inline');
      break;
    case 'piece_justificative':
      parent.children('.pj-template').addClass('show-inline');
      break;
    case 'carte':
      parent.children('.carte-options').addClass('show-inline');
      break;
    case 'explication':
      $('.mandatory', parent).hide();
      break;
  }
});
