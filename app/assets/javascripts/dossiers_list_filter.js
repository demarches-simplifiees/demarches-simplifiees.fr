$(document).on('page:load', filters_init);
$(document).ready(filters_init);

function filters_init() {
    $('html').click(function(event) { 
        var visible_filter = $('.filter_framed:visible')
        if(visible_filter.length) {
          if (!$(event.target).closest('.filter_framed').is(":visible")) {
            visible_filter.hide();
          }
        }        
    });

    $(".filter").on('click', function (event) {
        filter_framed_show(event);
        filter_framed_close_all_excepted(framed_id(event));
        event.stopPropagation();
    });

    $(".erase-filter").on('click', function (event) {
      $(this).parent().find(".filter_input").val("");
    });
}

function filter_framed_close_all_excepted(id) {
    $(".filter_framed:not("+id+")").hide();

    $(id).toggle();
}

function framed_id(event) {
    return "#framed_" + event.target.id
}

function filter_framed_show(event) {
    dom_object = $(framed_id(event));

    dom_object.css('top', (event.pageY + 7) + 'px');
    dom_object.css('left', (event.pageX + 7) + 'px');
}
