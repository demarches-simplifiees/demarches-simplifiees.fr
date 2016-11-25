$(document).on('page:load', init_default_data_block);
$(document).ready(init_default_data_block);

function init_default_data_block() {
    $('.default_data_block .title').click(function () {
        toggle_default_data_bloc(this, 400);
    });

    $('.default_data_block.default_visible').each(function() {
        toggle_default_data_bloc($(this).find('.title'), 0);
    });

    function toggle_default_data_bloc(element, duration){
        var block = $(element).parents('.show-block');
        if (block.attr("id") == "messages") {
          block.children(".last-message").toggle();
        }

        block.children(".body").slideToggle(duration);

        block.find(".carret-right").toggle();
        block.find(".carret-down").toggle();
    }
}
