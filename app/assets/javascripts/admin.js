$(document).on('turbolinks:load', init_admin);

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

        parent = $(this).parent().parent();

        parent.removeClass('header_section');
        parent.children(".drop_down_list").removeClass('show_inline');
        $('.mandatory', parent).show();

        switch(this.value){
            case 'header_section':
                parent.addClass('header_section');
                break;
            case 'drop_down_list':
            case 'multiple_drop_down_list':
                parent.children(".drop_down_list").addClass('show_inline');
                break;
            case 'explication':
                $('.mandatory', parent).hide();
                break;
        }
    });
}
