$(document).on('turbolinks:load', pref_list_dossier_actions);

function pref_list_dossier_actions() {
  pref_list_dossier_open_action();
  pref_list_dossier_close_action();
}

function pref_list_dossier_open_action() {
  $("#pref-list-dossier-open-action").on('click', function () {
    $("#pref-list-menu").css('display', 'block');
    $("#pref-list-menu").css('visibility', 'visible');

    $("#pref-list-menu").animate({
      right: 0
    }, 250);
  });
}

function pref_list_dossier_close_action() {
  $("#pref-list-dossier-close-action").on('click', function () {
    $("#pref-list-menu").animate({
        right: parseInt($("#pref-list-menu").css('width'), 10)*(-1)+'px'
      },{
        duration: 250,
        complete: function () {
          $("#pref-list-menu").css('display', 'none');
          $("#pref-list-menu").css('visibility', 'hidden');
        }
      }
    )
  });
}
