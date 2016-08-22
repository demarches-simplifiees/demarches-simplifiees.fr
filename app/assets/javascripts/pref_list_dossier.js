$(document).on('page:load', pref_list_dossier_actions);
$(document).ready(pref_list_dossier_actions);

function pref_list_dossier_actions() {
    pref_list_dossier_open_action();
    pref_list_dossier_close_action();
}

function pref_list_dossier_open_action() {
    $("#pref_list_dossier_open_action").on('click', function () {
        $("#pref_list_menu").css('display', 'block');
        $("#pref_list_menu").css('visibility', 'visible');

        $("#pref_list_menu").animate({
            right: 0
        }, 250);
    });
}

function pref_list_dossier_close_action() {
    $("#pref_list_dossier_close_action").on('click', function () {
        $("#pref_list_menu").animate({
                right: parseInt($("#pref_list_menu").css('width'), 10)*(-1)+'px'
            },{
                duration: 250,
                complete: function () {
                    $("#pref_list_menu").css('display', 'none');
                    $("#pref_list_menu").css('visibility', 'hidden');
                }
            }
        )
    });
}