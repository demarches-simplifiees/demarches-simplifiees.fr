import Rails from '@rails/ujs';
import debounce from 'debounce';

export { debounce };
export const { fire, csrfToken } = Rails;

export function show(el: HTMLElement) {
  el && el.classList.remove('hidden');
}

export function hide(el: HTMLElement) {
  el && el.classList.add('hidden');
}

export function toggle(el: HTMLElement, force?: boolean) {
  if (force == undefined) {
    el && el.classList.toggle('hidden');
  } else if (force) {
    el && el.classList.remove('hidden');
  } else {
    el && el.classList.add('hidden');
  }
}

export function enable(el: HTMLInputElement) {
  el && (el.disabled = false);
}

export function disable(el: HTMLInputElement) {
  el && (el.disabled = true);
}

export function hasClass(el: HTMLElement, cssClass: string) {
  return el && el.classList.contains(cssClass);
}

export function addClass(el: HTMLElement, cssClass: string) {
  el && el.classList.add(cssClass);
}

export function removeClass(el: HTMLElement, cssClass: string) {
  el && el.classList.remove(cssClass);
}

export function delegate(
  eventNames: string,
  selector: string,
  callback: () => void
) {
  eventNames
    .split(' ')
    .forEach((eventName) =>
      Rails.delegate(document, selector, eventName, callback)
    );
}

// A promise-based wrapper for Rails.ajax().
//
// Returns a Promise that is either:
// - resolved in case of a 20* HTTP response code,
// - rejected with an Error object otherwise.
//
// See Rails.ajax() code for more details.
export function ajax(options: Rails.AjaxOptions) {
  return new Promise((resolve, reject) => {
    Object.assign(options, {
      success: (
        response: unknown,
        statusText: string,
        xhr: { status: number }
      ) => {
        resolve({ response, statusText, xhr });
      },
      error: (
        response: unknown,
        statusText: string,
        xhr: { status: number }
      ) => {
        // NB: on HTTP/2 connections, statusText is always empty.
        const error = new Error(
          `Erreur ${xhr.status}` + (statusText ? ` : ${statusText}` : '')
        );
        Object.assign(error, { response, statusText, xhr });
        reject(error);
      }
    });
    Rails.ajax(options);
  });
}

export function getJSON(url: string, data: unknown, method = 'GET') {
  const { query, ...options } = fetchOptions(data, method);

  return fetch(`${url}${query}`, options).then((response) => {
    if (response.ok) {
      if (response.status === 204) {
        return null;
      }
      return response.json();
    }
    const error = new Error(String(response.statusText || response.status));
    (error as any).response = response;
    throw error;
  });
}

export function scrollTo(container: HTMLElement, scrollTo: HTMLElement) {
  container.scrollTop =
    offset(scrollTo).top - offset(container).top + container.scrollTop;
}

export function scrollToBottom(container: HTMLElement) {
  container.scrollTop = container.scrollHeight;
}

export function on(
  selector: string,
  eventName: string,
  fn: (event: Event, detail: unknown) => void
) {
  [...document.querySelectorAll(selector)].forEach((element) =>
    element.addEventListener(eventName, (event) =>
      fn(event, (event as CustomEvent).detail)
    )
  );
}

export function isNumeric(s: string) {
  const n = parseFloat(s);
  return !isNaN(n) && isFinite(n);
}

function offset(element: HTMLElement) {
  const rect = element.getBoundingClientRect();
  return {
    top: rect.top + document.body.scrollTop,
    left: rect.left + document.body.scrollLeft
  };
}

// Takes a promise, and return a promise that times out after the given delay.
export function timeoutable<T>(
  promise: Promise<T>,
  timeoutDelay: number
): Promise<T> {
  const timeoutPromise = new Promise<T>((resolve, reject) => {
    setTimeout(() => {
      reject(new Error(`Promise timed out after ${timeoutDelay}ms`));
    }, timeoutDelay);
  });
  return Promise.race([promise, timeoutPromise]);
}

const FETCH_TIMEOUT = 30 * 1000; // 30 sec

function fetchOptions(data: unknown, method = 'GET') {
  const options: RequestInit & {
    query: string;
    headers: Record<string, string>;
  } = {
    query: '',
    method: method.toUpperCase(),
    headers: {
      accept: 'application/json',
      'x-csrf-token': csrfToken() ?? '',
      'x-requested-with': 'XMLHttpRequest'
    },
    credentials: 'same-origin'
  };

  if (data) {
    if (options.method === 'GET') {
      options.query = objectToQuerystring(data as Record<string, string>);
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

function objectToQuerystring(obj: Record<string, string>): string {
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
