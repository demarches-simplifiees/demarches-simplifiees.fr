$(document).on('page:load', destroy_action);
$(document).ready(destroy_action);

function destroy_action(){
    $("#destroy").on('click', function(){
        $("#destroy").hide();
        $("#confirm").show();
    });

    $("#confirm #cancel").on('click', function(){
        $("#destroy").show();
        $("#confirm").hide();
    });
}