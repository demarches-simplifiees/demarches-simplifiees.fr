$(document).on('turbolinks:load', button_edit_procedure_init);

function button_edit_procedure_init(){
    buttons_api_carto();
    button_cerfa();
    button_individual();
}

function buttons_api_carto () {

    $("#procedure_module_api_carto_use_api_carto").on('change', function() {
        $("#modules_api_carto").toggle()
    });

    if ($('#procedure_module_api_carto_use_api_carto').is(':checked'))
        $("#modules_api_carto").show();
}

function button_cerfa () {

    $("#procedure_cerfa_flag").on('change', function() {
        $("#procedure_lien_demarche").toggle()
    });

    if ($('#procedure_cerfa_flag').is(':checked'))
        $("#procedure_lien_demarche").show();
}

function button_individual () {

    $("#procedure_for_individual").on('change', function() {
        $("#individual_with_siret").toggle()
    });

    if ($('#procedure_for_individual').is(':checked'))
        $("#individual_with_siret").show();
}
