$(document).on("click", "body", function () {
  $(".header-menu").removeClass("open fade-in-down");
});

DS.toggleHeaderMenu = function(event) {
  event.stopPropagation();
  $(".header-menu").toggleClass("open fade-in-down");
}
