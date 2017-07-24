$(document).on('turbolinks:load', button_edit_procedure_init);

function button_edit_procedure_init(){
  buttons_api_carto();
  button_cerfa();
  button_individual();
}

function buttons_api_carto () {

  $("#procedure-module-api-carto-use-api-carto").on('change', function() {
    $("#modules-api-carto").toggle()
  });

  if ($('#procedure-module-api-carto-use-api-carto').is(':checked'))
    $("#modules-api-carto").show();
}

function button_cerfa () {

  $("#procedure_cerfa_flag").on('change', function() {
    $("#procedure-lien-demarche").toggle()
  });

  if ($('#procedure_cerfa_flag').is(':checked'))
    $("#procedure-lien-demarche").show();
}

function button_individual () {

  $("#procedure_for_individual").on('change', function() {
    $("#individual-with-siret").toggle()
  });

  if ($('#procedure_for_individual').is(':checked'))
    $("#individual-with-siret").show();
}
