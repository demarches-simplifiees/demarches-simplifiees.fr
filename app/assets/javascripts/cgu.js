$(document).on('page:load', buttons_anchor);
$(document).ready(buttons_anchor);

function buttons_anchor(){
    $("#cgu_menu_block").on('click', 'a', function(){
        event.preventDefault();
        $('html,body').animate({scrollTop:$(this.hash).offset().top-80}, 500);
    });
}