import $ from 'jquery';

function showNotFound() {
  $('.dossier-link .text-info').hide();
  $('.dossier-link .text-warning').show();
}

function showData(data) {
  $('.dossier-link .dossier-text-summary').text(data.textSummary);
  $('.dossier-link .text-info').show();
  $('.dossier-link .text-warning').hide();
}

function hideEverything() {
  $('.dossier-link .text-info').hide();
  $('.dossier-link .text-warning').hide();
}

function fetchProcedureLibelle(e) {
  const dossierId = $(e.target).val();
  if (dossierId) {
    $.get(`/users/dossiers/${dossierId}/text_summary`)
      .done(showData)
      .fail(showNotFound);
  } else {
    hideEverything();
  }
}

let timeOut;
function debounceFetchProcedureLibelle(e) {
  if (timeOut) {
    clearTimeout(timeOut);
  }
  timeOut = setTimeout(() => fetchProcedureLibelle(e), 300);
}

$(document).on(
  'input',
  '[data-type=dossier-link]',
  debounceFetchProcedureLibelle
);
