import Rails from '@rails/ujs';
import debounce from 'debounce';

export { debounce };
export const { fire, csrfToken } = Rails;

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

export function getJSON(url, data, method = 'GET') {
  const { query, ...options } = fetchOptions(data, method);

  return fetch(`${url}${query}`, options).then((response) => {
    if (response.ok) {
      if (response.status === 204) {
        return null;
      }
      return response.json();
    }
    const error = new Error(response.statusText || response.status);
    error.response = response;
    throw error;
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
  [...document.querySelectorAll(selector)].forEach((element) =>
    element.addEventListener(eventName, (event) => fn(event, event.detail))
  );
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

const FETCH_TIMEOUT = 30 * 1000; // 30 sec

function fetchOptions(data, method = 'GET') {
  const options = {
    query: '',
    method: method.toUpperCase(),
    headers: {
      accept: 'application/json',
      'x-csrf-token': csrfToken(),
      'x-requested-with': 'XMLHttpRequest'
    },
    credentials: 'same-origin'
  };

  if (data) {
    if (options.method === 'GET') {
      options.query = objectToQuerystring(data);
    } else {
      options.headers['content-type'] = 'application/json';
      options.body = JSON.stringify(data);
    }
  }

  if (window.AbortController) {
    const controller = new AbortController();
    options.signal = controller.signal;

    setTimeout(() => {
      controller.abort();
    }, FETCH_TIMEOUT);
  }

  return options;
}

function objectToQuerystring(obj) {
  return Object.keys(obj).reduce(function (query, key, i) {
    return [
      query,
      i === 0 ? '?' : '&',
      encodeURIComponent(key),
      '=',
      encodeURIComponent(obj[key])
    ].join('');
  }, '');
}
