$(document).on('page:load', the_terms);
$(document).ready(the_terms);
$(document).on('page:load', init_collapse);
$(document).ready(init_collapse);

function init_collapse() {

  $('.title').click(function() {
    var section = $(this).parents().closest(".show-block").children(".body");
    return section.slideToggle(500, function () {});
  });

}

function the_terms() {
    var the_terms = $("#dossier_autorisation_donnees");

    if(the_terms.size() == 0)
        return;

    check_value (the_terms);

    the_terms.click(function () {
        check_value (the_terms);
    });

    function check_value (the_terms){
        if (the_terms.is(":checked")) {
            $("#etape_suivante").removeAttr("disabled");
        } else {
            $("#etape_suivante").attr("disabled", "disabled");
        }
    }
}

function error_form_siret(invalid_siret){
    setTimeout(function(){
        $("input[type='submit']").val('Erreur SIRET');
    }, 10);

    $("input[type='submit']").removeClass('btn-success').addClass('btn-danger');

    $("#dossier_siret").addClass('input-error').val(invalid_siret).on('input', reset_form_siret);

}

function reset_form_siret(){
    $("input[type='submit']").removeClass('btn-danger').addClass('btn-success').val('Valider');
    $("#dossier_siret").removeClass('input-error');
}

function toggle_etape_1(){
    $('.row.etape.etape_1 .etapes_menu #logos').toggle(100);
    $('.row.etape.etape_1 .etapes_informations #description_procedure').toggle(100);
}
