TPS.scrollMessagerie = function () {
  var $ul = $(".messagerie ul").first();
  if($ul.length) {
    $ul.scrollTop($ul.prop('scrollHeight'));
  }
};

document.addEventListener("turbolinks:load", TPS.scrollMessagerie);
