import Rails from 'rails-ujs';
import $ from 'jquery';
import debounce from 'debounce';

export { debounce };
export const { fire, ajax } = Rails;

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
    .forEach(eventName =>
      Rails.delegate(document, selector, eventName, callback)
    );
}

export function getJSON(url, data, method = 'get') {
  data = method !== 'get' ? JSON.stringify(data) : data;
  return $.ajax({
    method,
    url,
    data,
    contentType: 'application/json',
    dataType: 'json'
  });
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

export function to(promise) {
  return promise.then(result => [result]).catch(error => [null, error]);
}

function offset(element) {
  const rect = element.getBoundingClientRect();
  return {
    top: rect.top + document.body.scrollTop,
    left: rect.left + document.body.scrollLeft
  };
}
