import $ from 'jquery';

export function togglePrintMenu(event) {
  event.stopPropagation();
  $('.print-menu').toggleClass('open fade-in-down');
}
