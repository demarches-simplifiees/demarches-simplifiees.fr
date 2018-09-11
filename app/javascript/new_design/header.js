import $ from 'jquery';

export function toggleHeaderMenu(event) {
  event.stopPropagation();
  $('.header-menu').toggleClass('open fade-in-down');
}
