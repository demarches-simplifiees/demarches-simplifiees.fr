window.TPS = window.TPS || {};

$(document).on("click", "body", function () {
  $(".header-menu").removeClass("open fade-in-down");
});

TPS.toggleHeaderMenu = function(event) {
  event.stopPropagation();
  $(".header-menu").toggleClass("open fade-in-down");
}
