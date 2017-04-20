$(document).on('turbolinks:load', init_search_anim);

function init_search_anim(){
  $("#search-area").on('click', search_fadeIn);
}

function search_fadeIn(){
  var search_area = $("#search-area");
  var body_dom = $('body');
  var positions = search_area.position();
  var width = search_area.width();

  search_area.css('position', 'fixed');
  search_area.css('top', positions.top + $('.navbar').height());
  search_area.css('left', positions.left);
  search_area.css('z-index', 300);
  search_area.css('width', width);
  search_area.find('#q').animate({ height: '50px' });
  search_area.find('#search-button').animate({ height: '50px' });

  body_dom.append(search_area);
  $('#mask-search').fadeIn(200);

  var body_width = body_dom.width();

  var search_area_width = body_width/2.5;

  search_area.animate({
    width: search_area_width,
    left: (body_width/2 - search_area_width/2 + 40)
  }, 400, function() {
    search_area.off();
    $("#search-area input").focus();

    $('#mask-search').on('click', search_fadeOut)
  });
}

function search_fadeOut(){
  var search_area = $("#search-area");

  $('#mask-search').fadeOut(200);

  search_area.fadeOut(200, function(){
    search_area.css('position', 'static');
    search_area.css('top', '');
    search_area.css('left', '');
    search_area.css('z-index', '');
    search_area.css('width', 'auto');
    search_area.find('#q').css('height', 34);
    search_area.find('#search-button').css('height', 34);

    $('#search-block').append(search_area);
    search_area.fadeIn(200);

    init_search_anim();
  });

}
