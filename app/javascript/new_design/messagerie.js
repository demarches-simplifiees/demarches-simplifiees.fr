import $ from 'jquery';

export function scrollMessagerie() {
  const $ul = $('.messagerie ul').first();

  if ($ul.length) {
    const $elementToScroll = $('.date.highlighted').first();

    if ($elementToScroll.length != 0) {
      scrollTo($ul, $elementToScroll);
    } else {
      scrollToBottom($ul);
    }
  }
}

function scrollTo($container, $scrollTo) {
  $container.scrollTop(
    $scrollTo.offset().top - $container.offset().top + $container.scrollTop()
  );
}

function scrollToBottom($container) {
  $container.scrollTop($container.prop('scrollHeight'));
}

addEventListener('turbolinks:load', scrollMessagerie);
