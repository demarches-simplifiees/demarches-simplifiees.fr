$(document).on('page:load', all_video);
$(document).ready(all_video);

function all_video() {
    $(".all_video").on('click', function(event){
        $("#all_video").slideToggle(200);

        if (event.stopPropagation) {
            event.stopPropagation();
        }
        event.cancelBubble = true;

        return false;
    });
}


