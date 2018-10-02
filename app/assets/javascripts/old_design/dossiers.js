$(document).on('turbolinks:load', handle_siret_form_errors);

function error_form_siret(invalid_siret) {
  setTimeout(function () {
      $("input[type='submit']").val('Erreur SIRET');
  }, 10);

  $("input[type='submit']").removeClass('btn-success').addClass('btn-danger');

  $("#dossier-siret").addClass('input-error').val(invalid_siret).on('input', reset_form_siret);

}

function reset_form_siret() {
  $("input[type='submit']").removeClass('btn-danger').addClass('btn-success').val('Valider');
  $("#dossier-siret").removeClass('input-error');
}

function toggle_etape_1() {
  $('.row.etape.etape_1 .etapes-menu #logos').toggle(100);
  $('.row.etape.etape_1 .etapes-informations #description_procedure').toggle(100);
}

function handle_siret_form_errors() {
  $(".form-inline[data-remote]").on("ajax:error", function(event) {
    var input = $('#dossier-siret', event.target);
    if (input.length) {
      var invalid_siret = input.val();
      error_form_siret(invalid_siret);
    }
  });
}
