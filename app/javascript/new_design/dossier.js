$(document).on('click', 'body', () => {
  $('.print-menu').removeClass('open fade-in-down');
});

export function togglePrintMenu(event) {
  event.stopPropagation();
  $('.print-menu').toggleClass('open fade-in-down');
}
