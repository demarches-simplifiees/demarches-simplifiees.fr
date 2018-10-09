import { fire, getJSON, delegate as _delegate } from 'better-ujs';
import debounce from 'debounce';

export { debounce, fire, getJSON };

export function show({ classList }) {
  classList.remove('hidden');
}

export function hide({ classList }) {
  classList.add('hidden');
}

export function toggle({ classList }) {
  classList.toggle('hidden');
}

export function delegate(eventNames, selector, callback) {
  eventNames
    .split(' ')
    .forEach(eventName => _delegate(eventName, selector, callback));
}

export function scrollTo(container, scrollTo) {
  container.scrollTop =
    offset(scrollTo).top - offset(container).top + container.scrollTop;
}

export function scrollToBottom(container) {
  container.scrollTop = container.scrollHeight;
}

export function on(selector, eventName, fn) {
  [...document.querySelectorAll(selector)].forEach(element =>
    element.addEventListener(eventName, event => fn(event, event.detail))
  );
}

function offset(element) {
  const rect = element.getBoundingClientRect();
  return {
    top: rect.top + document.body.scrollTop,
    left: rect.left + document.body.scrollLeft
  };
}
