$(document).on("click", "body", function () {
  $(".print-menu").removeClass("open fade-in-down");
});

DS.togglePrintMenu = function(event) {
  event.stopPropagation();
  $(".print-menu").toggleClass("open fade-in-down");
}
