import Rails from '@rails/ujs';
import $ from 'jquery';
import debounce from 'debounce';

export { debounce };
export const { fire } = Rails;

export function show(el) {
  el && el.classList.remove('hidden');
}

export function hide(el) {
  el && el.classList.add('hidden');
}

export function toggle(el, force) {
  if (force == undefined) {
    el & el.classList.toggle('hidden');
  } else if (force) {
    el && el.classList.remove('hidden');
  } else {
    el && el.classList.add('hidden');
  }
}

export function enable(el) {
  el && (el.disabled = false);
}

export function disable(el) {
  el && (el.disabled = true);
}

export function hasClass(el, cssClass) {
  return el && el.classList.contains(cssClass);
}

export function addClass(el, cssClass) {
  el && el.classList.add(cssClass);
}

export function removeClass(el, cssClass) {
  el && el.classList.remove(cssClass);
}

export function delegate(eventNames, selector, callback) {
  eventNames
    .split(' ')
    .forEach((eventName) =>
      Rails.delegate(document, selector, eventName, callback)
    );
}

export function ajax(options) {
  return new Promise((resolve, reject) => {
    Object.assign(options, {
      success: (response, statusText, xhr) => {
        resolve({ response, statusText, xhr });
      },
      error: (response, statusText, xhr) => {
        let error = new Error(`Erreur ${xhr.status} : ${statusText}`);
        Object.assign(error, { response, statusText, xhr });
        reject(error);
      }
    });
    Rails.ajax(options);
  });
}

export function getJSON(url, data, method = 'get') {
  data = method !== 'get' && data ? JSON.stringify(data) : data;
  return Promise.resolve(
    $.ajax({
      method,
      url,
      data,
      contentType: 'application/json',
      dataType: 'json'
    })
  );
}

export function scrollTo(container, scrollTo) {
  container.scrollTop =
    offset(scrollTo).top - offset(container).top + container.scrollTop;
}

export function scrollToBottom(container) {
  container.scrollTop = container.scrollHeight;
}

export function on(selector, eventName, fn) {
  [...document.querySelectorAll(selector)].forEach((element) =>
    element.addEventListener(eventName, (event) => fn(event, event.detail))
  );
}

export function to(promise) {
  return promise.then((result) => [result]).catch((error) => [null, error]);
}

export function isNumeric(n) {
  return !isNaN(parseFloat(n)) && isFinite(n);
}

function offset(element) {
  const rect = element.getBoundingClientRect();
  return {
    top: rect.top + document.body.scrollTop,
    left: rect.left + document.body.scrollLeft
  };
}

// Takes a promise, and return a promise that times out after the given delay.
export function timeoutable(promise, timeoutDelay) {
  let timeoutPromise = new Promise((resolve, reject) => {
    setTimeout(() => {
      reject(new Error(`Promise timed out after ${timeoutDelay}ms`));
    }, timeoutDelay);
  });
  return Promise.race([promise, timeoutPromise]);
}
