import $ from 'jquery';

export function showMotivation(event, state) {
  event.preventDefault();
  $(`.motivation.${state}`).show();
  $('.dropdown-items').hide();
}

export function motivationCancel() {
  $('.motivation').hide();
  $('.dropdown-items').show();
}
