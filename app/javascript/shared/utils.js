import Rails from 'rails-ujs';
import $ from 'jquery';
import debounce from 'debounce';

export { debounce };
export const { fire } = Rails;

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
  $(container).scrollTop(
    $(scrollTo).offset().top -
      $(container).offset().top +
      $(container).scrollTop()
  );
}

export function scrollToBottom(container) {
  $(container).scrollTop(container.scrollHeight);
}

export function on(selector, eventName, fn) {
  [...document.querySelectorAll(selector)].forEach(element =>
    element.addEventListener(eventName, event => fn(event, event.detail))
  );
}
