$(document).on('page:load', init_admin);
$(document).ready(init_admin);

function init_admin(){
    destroy_action();
    on_change_type_de_champ_select();
}

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

function on_change_type_de_champ_select (){

    $("select.form-control.type_champ").on('change', function(e){

        parent = $(this).parent().parent()

        if (this.value === 'header_section') {
            parent.addClass('header_section')
        }
        else {
            parent.removeClass('header_section')
        }
    })
}