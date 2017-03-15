$(document).on('page:load', activeSelect2);
$(document).ready(activeSelect2);

function activeSelect2() {
  $('select.select2').select2({ theme: "bootstrap", width: '100%' });
}
