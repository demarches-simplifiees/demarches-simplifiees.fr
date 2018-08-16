import $ from 'jquery';

$(document).on('click', 'body', () => {
  $('.header-menu').removeClass('open fade-in-down');
});

export function toggleHeaderMenu(event) {
  event.stopPropagation();
  $('.header-menu').toggleClass('open fade-in-down');
}
