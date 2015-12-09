$(document).on('page:load', buttons_api_carto);
$(document).ready(buttons_api_carto);

function buttons_api_carto () {

    $("#procedure_module_api_carto_use_api_carto").on('change', function() {
        $("#modules_api_carto").toggle()
    });

    if ($('#procedure_module_api_carto_use_api_carto').is(':checked'))
        $("#modules_api_carto").show();
}