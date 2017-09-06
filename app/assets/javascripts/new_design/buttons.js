$(document).on("click", "body", function () {
  $(".button.dropdown").removeClass("open");
});

$(document).on("click", ".button.dropdown", function(event) {
  event.stopPropagation();
  var $target = $(event.target);
  if($target.hasClass("button", "dropdown")){
    $target.toggleClass("open");
  }
});
