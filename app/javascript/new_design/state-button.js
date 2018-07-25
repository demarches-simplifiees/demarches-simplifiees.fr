export function showMotivation(state) {
  $(`.motivation.${state}`).show();
  $('.dropdown-items').hide();
}

export function motivationCancel() {
  $('.motivation').hide();
  $('.dropdown-items').show();
}
