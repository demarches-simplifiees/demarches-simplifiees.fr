DS.scrollMessagerie = function () {
  var scrollTo = function ($container, $scrollTo) {
    $container.scrollTop(
      $scrollTo.offset().top - $container.offset().top + $container.scrollTop()
    );
  }

  var scrollToBottom = function ($container) {
    $container.scrollTop($container.prop('scrollHeight'));
  }

  var $ul = $(".messagerie ul").first();
  if($ul.length) {
    var $elementToScroll = $('.date.highlighted').first();

    if ($elementToScroll.length != 0) {
      scrollTo($ul, $elementToScroll);
    } else {
      scrollToBottom($ul);
    }
  }
};

document.addEventListener("turbolinks:load", DS.scrollMessagerie);
