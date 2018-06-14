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

  $("#liste-gestionnaire #libelle").on('click', function(){
    setTimeout(destroy_action, 500);
  });
}

function on_change_type_de_champ_select (){
  $("select.form-control.type-champ").on('change', function(e){

    parent = $(this).parent().parent();

    parent.removeClass('header-section');
    parent.children(".drop-down-list").removeClass('show-inline');
    parent.children(".pj-template").removeClass('show-inline');

    $('.mandatory', parent).show();

    switch(this.value){
      case 'header_section':
        parent.addClass('header-section');
        break;
      case 'drop_down_list':
      case 'multiple_drop_down_list':
      case 'linked_drop_down_list':
        parent.children(".drop-down-list").addClass('show-inline');
        break;
      case 'piece_justificative':
        parent.children(".pj-template").addClass('show-inline');
        break;
      case 'explication':
        $('.mandatory', parent).hide();
        break;
    }
  });
}
