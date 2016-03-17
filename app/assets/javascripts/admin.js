$(document).on('page:load', destroy_action);
$(document).ready(destroy_action);

function destroy_action(){
    $(".delete").on('click', function(){
        $(this).hide();
        $(this).closest('td').find(".confirm").show();
    });

    $(".cancel").on('click', function(){
        $(this).closest('td').find(".delete").show();
        $(this).closest('td').find(".confirm").hide();
    });

    $("#liste_gestionnaire #libelle").on('click', function(){
        setTimeout(destroy_action, 500);
    });
}