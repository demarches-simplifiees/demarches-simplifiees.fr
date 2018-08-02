$(document).on('turbolinks:load', buttons_archived);

function buttons_archived(){
  $("button#archive-procedure").on('click', function(){
    $("button#archive-procedure").hide();
    $("#confirm").show();
  });

  $("#confirm #cancel").on('click', function(){
    $("button#archive-procedure").show();
    $("#confirm").hide();
  });
}
