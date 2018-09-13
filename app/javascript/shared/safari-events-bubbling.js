// Mobile Safari doesn't bubble mouse events by default, unless:
//
// - the target element of the event is a link or a form field.
// - the target element, or any of its ancestors up to but not including the <body>, has an explicit event handler set for any of the mouse events. This event handler may be an empty function.
// - the target element, or any of its ancestors up to and including the document has a cursor: pointer CSS declarations.
//
// (See https://www.quirksmode.org/blog/archives/2014/02/mouse_event_bub.html)
//
// This is a problem for us, because we bind a lot of click events as
// `document.on('click', '.my-element', …)` – which requires proper bubbling.
//
// To fix this globally, add an empty event handler to a non-body parent element.
// This will force all mouse events to bubble on Mobile Safari.

addEventListener('turbolinks:load', () => {
  document.querySelector('.page-wrapper').addEventListener('click', () => {});
});
